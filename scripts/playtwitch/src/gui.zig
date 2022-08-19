const std = @import("std");
const c_allocator = std.heap.c_allocator;
const ffi = @import("ffi.zig");
const c = ffi.c;

var chatty_alive = false;

pub const GuiState = struct {
    /// An arena allocator used to store userdata for widgets of the UI
    udata_arena: std.mem.Allocator,
};

pub fn activate(app: *c.GtkApplication, state: *GuiState) void {
    const win = c.gtk_application_window_new(app);
    c.gtk_window_set_title(@ptrCast(*c.GtkWindow, win), "Pick a stream!");

    const titlebar = c.gtk_header_bar_new();
    c.gtk_window_set_titlebar(@ptrCast(*c.GtkWindow, win), titlebar);

    const left_titlebar = c.gtk_box_new(c.GTK_ORIENTATION_HORIZONTAL, 5);
    c.gtk_header_bar_pack_start(@ptrCast(*c.GtkHeaderBar, titlebar), left_titlebar);

    c.gtk_box_append(@ptrCast(*c.GtkBox, left_titlebar), c.gtk_label_new("Quality"));

    const quality_box = c.gtk_combo_box_text_new_with_entry();
    c.gtk_box_append(@ptrCast(*c.GtkBox, left_titlebar), quality_box);

    const preset_qualities = [_][:0]const u8{
        "best",
        "1080p60",
        "720p60",
        "480p",
        "360p",
        "worst",
        "audio_only",
    };
    for (&preset_qualities) |quality| {
        c.gtk_combo_box_text_append(
            @ptrCast(*c.GtkComboBoxText, quality_box),
            quality, // ID
            quality, // Text
        );
    }
    _ = c.gtk_combo_box_set_active_id(@ptrCast(*c.GtkComboBox, quality_box), "best");

    const right_titlebar = c.gtk_box_new(c.GTK_ORIENTATION_HORIZONTAL, 5);
    c.gtk_header_bar_pack_end(@ptrCast(*c.GtkHeaderBar, titlebar), right_titlebar);

    const chatty_switch = c.gtk_switch_new();
    c.gtk_box_append(@ptrCast(*c.GtkBox, right_titlebar), chatty_switch);

    c.gtk_switch_set_active(@ptrCast(*c.GtkSwitch, chatty_switch), 1);

    c.gtk_box_append(@ptrCast(*c.GtkBox, right_titlebar), c.gtk_label_new("Start Chatty"));

    const content = c.gtk_box_new(c.GTK_ORIENTATION_VERTICAL, 5);
    c.gtk_window_set_child(@ptrCast(*c.GtkWindow, win), content);

    const other_stream_buffer = c.gtk_entry_buffer_new(null, -1);
    const other_stream_entry = c.gtk_entry_new_with_buffer(other_stream_buffer);
    c.gtk_box_append(@ptrCast(*c.GtkBox, content), other_stream_entry);

    const dialog_buf = c.gtk_text_buffer_new(null);
    const dialog = streamlinkErrorDialog(@ptrCast(*c.GtkWindow, win), dialog_buf);

    c.gtk_entry_set_placeholder_text(
        @ptrCast(*c.GtkEntry, other_stream_entry),
        "Other Channel...",
    );
    const other_act_data = state.udata_arena.create(OtherStreamActivateData) catch return;
    other_act_data.* = OtherStreamActivateData{
        .state = state,
        .buf = other_stream_buffer,
        .win = @ptrCast(*c.GtkWindow, win),
        .chatty_switch = @ptrCast(*c.GtkSwitch, chatty_switch),
        .quality_box = @ptrCast(*c.GtkComboBoxText, quality_box),
        .dialog = dialog,
        .text_buf = dialog_buf,
    };

    ffi.connectSignal(
        other_stream_entry,
        "activate",
        @ptrCast(c.GCallback, onOtherStreamActivate),
        other_act_data,
    );

    const frame = c.gtk_frame_new("Quick Pick");
    c.gtk_box_append(@ptrCast(*c.GtkBox, content), frame);

    const scroll = c.gtk_scrolled_window_new();
    c.gtk_frame_set_child(@ptrCast(*c.GtkFrame, frame), scroll);

    c.gtk_widget_set_hexpand(scroll, 1);
    c.gtk_widget_set_vexpand(scroll, 1);
    c.gtk_scrolled_window_set_policy(
        @ptrCast(*c.GtkScrolledWindow, scroll),
        c.GTK_POLICY_AUTOMATIC,
        c.GTK_POLICY_ALWAYS,
    );

    const list = c.gtk_list_box_new();
    c.gtk_scrolled_window_set_child(@ptrCast(*c.GtkScrolledWindow, scroll), list);

    const act_data = state.udata_arena.create(RowActivateData) catch return;

    act_data.* = RowActivateData{
        .state = state,
        .win = @ptrCast(*c.GtkWindow, win),
        .chatty_switch = @ptrCast(*c.GtkSwitch, chatty_switch),
        .quality_box = @ptrCast(*c.GtkComboBoxText, quality_box),
        .dialog = dialog,
        .text_buf = dialog_buf,
    };

    ffi.connectSignal(list, "row-activated", @ptrCast(c.GCallback, onRowActivate), act_data);

    channels: {
        const channels_data = readChannels() catch |e| {
            std.log.err("Failed to read channels: {}", .{e});
            break :channels;
        };
        defer c_allocator.free(channels_data);

        var name_buf: [64]u8 = undefined;

        var channels_iter = std.mem.split(u8, channels_data, "\n");
        while (channels_iter.next()) |s| {
            if (s.len > 63) {
                @panic("Can't have channel name >63 chars!");
            }
            std.mem.copy(u8, &name_buf, s);
            name_buf[s.len] = 0;

            const label = c.gtk_label_new(&name_buf);
            c.gtk_list_box_append(@ptrCast(*c.GtkListBox, list), label);
            c.gtk_widget_set_halign(label, c.GTK_ALIGN_START);
        }
    }

    c.gtk_widget_show(win);
}

fn readChannels() ![]u8 {
    const home = try std.os.getenv("HOME") orelse error.HomeNotSet;
    const fname = try std.fmt.allocPrint(c_allocator, "{s}/.config/playtwitch/channels", .{home});
    defer c_allocator.free(fname);
    std.log.info("Reading channels from {s}", .{fname});
    const file = try std.fs.cwd().openFile(fname, .{});
    return try file.readToEndAlloc(c_allocator, 1024 * 1024 * 5);
}

const RowActivateData = struct {
    state: *GuiState,
    win: *c.GtkWindow,
    chatty_switch: *c.GtkSwitch,
    quality_box: *c.GtkComboBoxText,
    dialog: *c.GtkWidget,
    text_buf: *c.GtkTextBuffer,
};

fn onRowActivate(list: *c.GtkListBox, row: *c.GtkListBoxRow, data: *RowActivateData) void {
    _ = list;
    const label = c.gtk_list_box_row_get_child(row);
    const channel_name = c.gtk_label_get_text(@ptrCast(*c.GtkLabel, label));
    const quality = c.gtk_combo_box_text_get_active_text(data.quality_box);
    defer c.g_free(quality);

    start(.{
        .chatty = c.gtk_switch_get_active(data.chatty_switch) != 0,
        .channel = std.mem.span(channel_name),
        .quality = std.mem.span(quality),
        .crash_dialog = data.dialog,
        .error_text_buf = data.text_buf,
        .window = data.win,
    }) catch |err| std.log.err("Failed to start children: {}", .{err});

    c.gtk_widget_hide(@ptrCast(*c.GtkWidget, data.win));
}

const OtherStreamActivateData = struct {
    state: *GuiState,
    buf: *c.GtkEntryBuffer,
    win: *c.GtkWindow,
    chatty_switch: *c.GtkSwitch,
    quality_box: *c.GtkComboBoxText,
    dialog: *c.GtkWidget,
    text_buf: *c.GtkTextBuffer,
};

fn onOtherStreamActivate(entry: *c.GtkEntry, data: *OtherStreamActivateData) void {
    _ = entry;
    const quality = c.gtk_combo_box_text_get_active_text(data.quality_box);
    defer c.g_free(quality);

    start(.{
        .chatty = c.gtk_switch_get_active(data.chatty_switch) != 0,
        .channel = c.gtk_entry_buffer_get_text(
            data.buf,
        )[0..c.gtk_entry_buffer_get_length(data.buf)],
        .quality = std.mem.span(quality),
        .crash_dialog = data.dialog,
        .error_text_buf = data.text_buf,
        .window = data.win,
    }) catch |err| std.log.err("Failed to start children: {}", .{err});

    c.gtk_widget_hide(@ptrCast(*c.GtkWidget, data.win));
}

pub fn streamlinkErrorDialog(parent_window: *c.GtkWindow, output: *c.GtkTextBuffer) *c.GtkWidget {
    const dialog = c.gtk_dialog_new_with_buttons(
        "Streamlink Crashed!",
        parent_window,
        c.GTK_DIALOG_MODAL,
        "_Close",
        c.GTK_RESPONSE_CLOSE,
        "_Cancel",
        c.GTK_RESPONSE_REJECT,
        @as(?*anyopaque, null),
    );

    ffi.connectSignal(
        dialog,
        "response",
        @ptrCast(c.GCallback, onErrorDialogResponse),
        parent_window,
    );

    const content = c.gtk_dialog_get_content_area(@ptrCast(*c.GtkDialog, dialog));
    c.gtk_box_set_spacing(@ptrCast(*c.GtkBox, content), 5);
    c.gtk_widget_set_margin_top(content, 5);
    c.gtk_widget_set_margin_bottom(content, 5);
    c.gtk_widget_set_margin_start(content, 5);
    c.gtk_widget_set_margin_end(content, 5);
    c.gtk_box_append(
        @ptrCast(*c.GtkBox, content),
        c.gtk_label_new("Streamlink Crashed! This is the output."),
    );

    const output_view = c.gtk_text_view_new_with_buffer(output);
    c.gtk_widget_set_hexpand(output_view, 1);
    c.gtk_text_view_set_editable(@ptrCast(*c.GtkTextView, output_view), 0);
    c.gtk_box_append(@ptrCast(*c.GtkBox, content), output_view);

    return dialog;
}

fn onErrorDialogResponse(dialog: *c.GtkDialog, response_id: c_int, window: *c.GtkWindow) void {
    switch (response_id) {
        c.GTK_RESPONSE_DELETE_EVENT, c.GTK_RESPONSE_REJECT => {
            c.gtk_window_close(window);
        },
        c.GTK_RESPONSE_CLOSE => {
            c.gtk_widget_hide(@ptrCast(*c.GtkWidget, dialog));
            c.gtk_widget_show(@ptrCast(*c.GtkWidget, window));
        },
        else => {},
    }
}

const StartOptions = struct {
    /// if true, start chatty
    chatty: bool,
    /// name of the channel to launch
    channel: []const u8,
    /// quality parameter for streamlink
    quality: []const u8,
    /// a pointer to a GTK widget that'll be shown if streamlink crashes
    crash_dialog: *c.GtkWidget,
    /// GtkTextBuffer to save streamlink's output in in the case of a crash
    /// so it can be displayed
    error_text_buf: *c.GtkTextBuffer,
    /// the main GTK window
    window: *c.GtkWindow,
};

fn start(options: StartOptions) !void {
    if (options.channel.len == 0) {
        std.log.warn("Exiting due to attempt to start empty channel", .{});
        return;
    }

    var err: ?*c.GError = null;

    std.log.info(
        "Starting for channel {s} with quality {s} (chatty: {})",
        .{ options.channel, options.quality, options.chatty },
    );
    const url = try std.fmt.allocPrintZ(c_allocator, "https://twitch.tv/{s}", .{options.channel});
    defer c_allocator.free(url);
    const quality_z = try std.cstr.addNullByte(c_allocator, options.quality);
    defer c_allocator.free(quality_z);
    const streamlink_argv = [_][*c]const u8{ "streamlink", url, quality_z, null };
    const streamlink_subproc = c.g_subprocess_newv(
        &streamlink_argv,
        c.G_SUBPROCESS_FLAGS_STDOUT_PIPE,
        &err,
    );
    try ffi.handleGError(&err);

    const communicate_data = try c_allocator.create(StreamlinkCommunicateData);
    communicate_data.* = StreamlinkCommunicateData{
        .dialog = options.crash_dialog,
        .text_buf = options.error_text_buf,
        .window = options.window,
    };

    c.g_subprocess_communicate_async(
        streamlink_subproc,
        null,
        null,
        @ptrCast(c.GAsyncReadyCallback, streamlinkCommunicateCb),
        communicate_data,
    );

    if (options.chatty) {
        if (@atomicLoad(bool, &chatty_alive, .Unordered)) {
            std.log.warn("Chatty is already running, not starting again.", .{});
            return;
        }

        var chatty_arena = std.heap.ArenaAllocator.init(c_allocator);
        const channel_d = try chatty_arena.allocator().dupe(u8, options.channel);
        const chatty_argv = [_][]const u8{ "chatty", "-connect", "-channel", channel_d };
        const chatty_argv_dup = try chatty_arena.allocator().dupe([]const u8, &chatty_argv);
        var chatty_child = std.ChildProcess.init(
            chatty_argv_dup,
            c_allocator,
        );

        const thread = try std.Thread.spawn(
            .{},
            chattyThread,
            .{ chatty_child, chatty_arena },
        );
        thread.detach();
    }
}

fn chattyThread(child: std.ChildProcess, arena: std.heap.ArenaAllocator) !void {
    @atomicStore(bool, &chatty_alive, true, .Unordered);
    defer @atomicStore(bool, &chatty_alive, false, .Unordered);
    var ch = child;
    defer arena.deinit();
    _ = try ch.spawnAndWait();
}

const StreamlinkCommunicateData = struct {
    dialog: *c.GtkWidget,
    text_buf: *c.GtkTextBuffer,
    window: *c.GtkWindow,
};

fn streamlinkCommunicateCb(
    source_object: *c.GObject,
    res: *c.GAsyncResult,
    data: *StreamlinkCommunicateData,
) void {
    defer c_allocator.destroy(data);

    var err: ?*c.GError = null;
    var stdout: ?*c.GBytes = null;
    _ = c.g_subprocess_communicate_finish(
        @ptrCast(*c.GSubprocess, source_object),
        res,
        &stdout,
        null,
        &err,
    );
    ffi.handleGError(&err) catch {
        std.log.err("Failed to communicate to streamlink child!", .{});
        c.gtk_window_close(data.window);
        return;
    };
    defer c.g_bytes_unref(stdout);

    const exit_code = c.g_subprocess_get_exit_status(@ptrCast(*c.GSubprocess, source_object));

    if (exit_code == 0) {
        std.log.info("Streamlink exited with code 0.", .{});
        c.gtk_window_close(data.window);
        return;
    }

    var len: usize = 0;
    const stdout_raw = @ptrCast([*c]const u8, c.g_bytes_get_data(stdout, &len));
    const stdout_data = std.mem.trimRight(u8, stdout_raw[0..len], " \n\r\t");

    // Streamlink exits with a nonzero code if the stream ends, but we don't
    // want to count this as a crash.
    if (std.mem.containsAtLeast(u8, stdout_data, 1, "Stream ended")) {
        std.log.warn(
            \\Streamlink exited with code {d}, but output contained
            \\"Stream ended", not showing popup. Full output:
            \\{s}
        ,
            .{ exit_code, stdout_data },
        );
        c.gtk_window_close(data.window);
        return;
    }

    c.gtk_text_buffer_set_text(
        data.text_buf,
        stdout_data.ptr,
        @intCast(c_int, stdout_data.len),
    );
    c.gtk_widget_show(data.dialog);
}
