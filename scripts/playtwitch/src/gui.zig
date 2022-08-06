const std = @import("std");
const ffi = @import("ffi.zig");
const c = ffi.c;

pub const GuiState = struct {
    alloc: std.mem.Allocator,
    /// An arena allocator used to store userdata for widgets of the UI
    udata_arena: std.mem.Allocator,

    streamlink_child: ?std.ChildProcess = null,
    chatty_child: ?std.ChildProcess = null,
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
    };

    ffi.connectSignal(list, "row-activated", @ptrCast(c.GCallback, onRowActivate), act_data);

    channels: {
        const channels_data = readChannels(state.alloc) catch |e| {
            std.log.err("Failed to read channels: {}", .{e});
            break :channels;
        };
        defer state.alloc.free(channels_data);

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

fn readChannels(alloc: std.mem.Allocator) ![]u8 {
    const home = try std.os.getenv("HOME") orelse error.HomeNotSet;
    const fname = try std.fmt.allocPrint(alloc, "{s}/.config/playtwitch/channels", .{home});
    defer alloc.free(fname);
    std.log.info("Reading channels from {s}", .{fname});
    const file = try std.fs.cwd().openFile(fname, .{});
    return try file.readToEndAlloc(alloc, 1024 * 1024 * 5);
}

const RowActivateData = struct {
    state: *GuiState,
    win: *c.GtkWindow,
    chatty_switch: *c.GtkSwitch,
    quality_box: *c.GtkComboBoxText,
};

fn onRowActivate(list: *c.GtkListBox, row: *c.GtkListBoxRow, data: *RowActivateData) void {
    _ = list;
    const label = c.gtk_list_box_row_get_child(row);
    const channel_name = c.gtk_label_get_text(@ptrCast(*c.GtkLabel, label));
    const quality = c.gtk_combo_box_text_get_active_text(data.quality_box);
    defer c.g_free(quality);

    start(
        data.state,
        if (c.gtk_switch_get_active(data.chatty_switch) == 0) false else true,
        std.mem.span(channel_name),
        std.mem.span(quality),
    ) catch |err| std.log.err("Failed to start children: {}", .{err});

    c.gtk_window_close(data.win);
}

const OtherStreamActivateData = struct {
    state: *GuiState,
    buf: *c.GtkEntryBuffer,
    win: *c.GtkWindow,
    chatty_switch: *c.GtkSwitch,
    quality_box: *c.GtkComboBoxText,
};

fn onOtherStreamActivate(entry: *c.GtkEntry, data: *OtherStreamActivateData) void {
    _ = entry;
    const quality = c.gtk_combo_box_text_get_active_text(data.quality_box);
    defer c.g_free(quality);

    start(
        data.state,
        if (c.gtk_switch_get_active(data.chatty_switch) == 0) false else true,
        ffi.getEntryBufferText(data.buf),
        std.mem.span(quality),
    ) catch |err| std.log.err("Failed to start children: {}", .{err});

    c.gtk_window_close(data.win);
}

fn start(
    state: *GuiState,
    chatty: bool,
    channel: []const u8,
    quality: []const u8,
) !void {
    if (channel.len == 0) {
        std.log.warn("Exiting due to attempt to start empty channel", .{});
        return;
    }

    std.log.info(
        "Starting for channel {s} with quality {s} (chatty: {})",
        .{ channel, quality, chatty },
    );
    const url = try std.fmt.allocPrint(state.alloc, "https://twitch.tv/{s}", .{channel});
    defer state.alloc.free(url);
    const streamlink_argv = [_][]const u8{ "streamlink", url, quality };
    var streamlink_child = std.ChildProcess.init(&streamlink_argv, state.alloc);
    try streamlink_child.spawn();
    state.streamlink_child = streamlink_child;

    if (chatty) {
        const chatty_argv = [_][]const u8{ "chatty", "-connect", "-channel", channel };
        var chatty_child = std.ChildProcess.init(&chatty_argv, state.alloc);
        try chatty_child.spawn();
        state.chatty_child = chatty_child;
    }
}
