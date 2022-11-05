const std = @import("std");
const c = @import("ffi.zig").c;
const igu = @import("ig_util.zig");
const launch = @import("launch.zig");
const State = @import("State.zig");

const StartType = union(enum) {
    none,
    channel_bar,
    channels_idx: usize,
};

pub fn winContent(state: *State) !void {
    state.mutex.lock();
    defer state.mutex.unlock();

    var start: StartType = .none;

    // Chatty checkbox
    _ = c.igCheckbox("Start Chatty", &state.chatty);

    // Quality input
    igu.sliceText("Quality ");
    c.igSameLine(0.0, 0.0);

    if (c.igInputText(
        "##quality_input",
        &state.quality_buf,
        state.quality_buf.len,
        c.ImGuiInputTextFlags_EnterReturnsTrue,
        null,
        null,
    )) {
        start = .channel_bar;
    }

    var quality_popup_pos: c.ImVec2 = undefined;
    c.igGetItemRectMin(&quality_popup_pos);
    var quality_popup_size: c.ImVec2 = undefined;
    c.igGetItemRectSize(&quality_popup_size);

    c.igSameLine(0.0, 0.0);
    if (c.igArrowButton("##open_quality_popup", c.ImGuiDir_Down)) {
        c.igOpenPopup_Str("quality_popup", 0);
    }
    // open popup on arrow button click
    c.igOpenPopupOnItemClick("quality_popup", 0);

    var btn_size: c.ImVec2 = undefined;
    c.igGetItemRectSize(&btn_size);

    const preset_qualities = [_][:0]const u8{
        "best",
        "1080p60",
        "720p60",
        "480p",
        "360p",
        "worst",
        "audio_only",
    };

    quality_popup_pos.y += quality_popup_size.y;
    quality_popup_size.x += btn_size.x;
    quality_popup_size.y += 5 + (quality_popup_size.y * @intToFloat(
        f32,
        preset_qualities.len,
    ));

    c.igSetNextWindowPos(quality_popup_pos, c.ImGuiCond_Always, .{ .x = 0.0, .y = 0.0 });
    c.igSetNextWindowSize(quality_popup_size, c.ImGuiCond_Always);

    if (c.igBeginPopup("quality_popup", c.ImGuiWindowFlags_NoMove)) {
        defer c.igEndPopup();

        for (preset_qualities) |quality| {
            if (c.igSelectable_Bool(quality.ptr, false, 0, .{ .x = 0.0, .y = 0.0 })) {
                std.mem.set(u8, &state.quality_buf, 0);
                std.mem.copy(u8, &state.quality_buf, quality);
            }
        }
    }

    igu.sliceText("Play Channel ");
    c.igSameLine(0.0, 0.0);
    if (c.igInputText(
        "##play_channel_input",
        &state.channel_name_buf,
        state.channel_name_buf.len,
        c.ImGuiInputTextFlags_EnterReturnsTrue,
        null,
        null,
    )) {
        start = .channel_bar;
    }
    c.igSameLine(0.0, 0.0);
    if (c.igButton("Play!", .{ .x = 0.0, .y = 0.0 })) {
        start = .channel_bar;
    }

    if (state.channels != null) {
        c.igBeginDisabled(state.live_status_loading);
        defer c.igEndDisabled();
        if (c.igButton("Refresh Status", .{ .x = 0.0, .y = 0.0 })) {
            (try std.Thread.spawn(.{}, @import("live.zig").reloadLiveThread, .{state}))
                .detach();
        }
    }

    if (state.channels != null and c.igBeginChild_Str(
        "Quick Pick",
        .{ .x = 0.0, .y = 0.0 },
        true,
        0,
    )) {
        _ = c.igBeginTable(
            "##qp_table",
            3,
            c.ImGuiTableFlags_Resizable,
            .{ .x = 0.0, .y = 0.0 },
            0.0,
        );
        defer c.igEndTable();

        c.igTableSetupColumn("Channel", 0, 0.0, 0);
        c.igTableSetupColumn("Comment", 0, 0.0, 0);
        c.igTableSetupColumn("Live?", c.ImGuiTableColumnFlags_WidthFixed, 80.0, 0);

        c.igTableHeadersRow();
        _ = c.igTableSetColumnIndex(0);
        c.igTableHeader("Channel");
        _ = c.igTableSetColumnIndex(1);
        c.igTableHeader("Comment");
        _ = c.igTableSetColumnIndex(2);
        c.igTableHeader("Live?");

        for (state.channels.?) |ch, i| {
            var ch_buf: [256]u8 = undefined;
            const formatted = try std.fmt.bufPrintZ(
                &ch_buf,
                "{s}",
                .{ch.name},
            );

            c.igPushID_Int(@intCast(c_int, i));
            defer c.igPopID();

            _ = c.igTableNextRow(0, 0.0);
            _ = c.igTableSetColumnIndex(0);

            if (c.igSelectable_Bool(
                formatted.ptr,
                false,
                c.ImGuiSelectableFlags_SpanAllColumns,
                .{ .x = 0.0, .y = 0.0 },
            )) {
                start = .{ .channels_idx = i };
            }

            _ = c.igTableSetColumnIndex(1);

            if (ch.comment) |comment| {
                igu.sliceText(comment);
            }

            _ = c.igTableSetColumnIndex(2);

            const live_color = switch (ch.live) {
                .loading => c.ImVec4{ .x = 1.0, .y = 1.0, .z = 0.0, .w = 1.0 },
                .live => c.ImVec4{ .x = 0.0, .y = 1.0, .z = 0.0, .w = 1.0 },
                .offline => c.ImVec4{ .x = 1.0, .y = 0.0, .z = 0.0, .w = 1.0 },
            };
            const live_label = switch (ch.live) {
                .loading => "Loading...",
                .live => "Live",
                .offline => "Offline",
            };

            const prev_col = c.igGetStyle().*.Colors[c.ImGuiCol_Text];
            c.igGetStyle().*.Colors[c.ImGuiCol_Text] = live_color;
            igu.sliceText(live_label);
            c.igGetStyle().*.Colors[c.ImGuiCol_Text] = prev_col;
        }
    }

    if (state.channels != null)
        c.igEndChild(); // END THE CHILD MWAAHAHA

    if (state.streamlink_out) |out| {
        c.igSetNextWindowSize(.{ .x = 400.0, .y = 150.0 }, c.ImGuiCond_Appearing);
        var open = true;
        if (c.igBeginPopupModal(
            "Streamlink Crashed!",
            &open,
            c.ImGuiWindowFlags_Modal,
        )) {
            defer c.igEndPopup();
            if (c.igBeginChild_Str(
                "##output",
                .{ .x = 0.0, .y = 0.0 },
                true,
                c.ImGuiWindowFlags_HorizontalScrollbar,
            ))
                igu.sliceText(out);
            c.igEndChild();
        } else {
            c.igOpenPopup_Str("Streamlink Crashed!", 0);
        }

        if (!open) {
            state.freeStreamlinkMemfd();
        }
    }

    if (start == .channel_bar and state.channel_name_buf[0] == 0) {
        std.log.warn("Tried to start an empty stream!", .{});
        start = .none;
    }

    switch (start) {
        .none => {},
        .channel_bar => {
            c.glfwHideWindow(state.win);
            try launch.launchChildren(
                state,
                std.mem.sliceTo(&state.channel_name_buf, 0),
            );
        },
        .channels_idx => |idx| {
            c.glfwHideWindow(state.win);
            try launch.launchChildren(state, state.channels.?[idx].name);
        },
    }
}
