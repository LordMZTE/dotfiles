const std = @import("std");
const ffi = @import("ffi.zig");
const c = ffi.c;

const blacklist = std.ComptimeStringMap(void, .{
    .{ "Endcards/Credits", {} },
    .{ "Interaction Reminder", {} },
    .{ "Intermission/Intro Animation", {} },
    .{ "Intro", {} },
    .{ "Outro", {} },
    .{ "Sponsor", {} },
    .{ "Unpaid/Self Promotion", {} },
});

pub const std_options = struct {
    pub const log_level = .debug;
    pub fn logFn(
        comptime message_level: std.log.Level,
        comptime scope: @TypeOf(.enum_literal),
        comptime format: []const u8,
        args: anytype,
    ) void {
        _ = scope;

        const stderr = std.io.getStdErr().writer();

        stderr.print("[sbskip {s}] " ++ format ++ "\n", .{@tagName(message_level)} ++ args) catch return;
    }
};

export fn mpv_open_cplugin(handle: *c.mpv_handle) callconv(.C) c_int {
    tryMain(handle) catch |e| {
        if (@errorReturnTrace()) |ert|
            std.debug.dumpStackTrace(ert.*);
        std.log.err("{}", .{e});
        return -1;
    };
    return 0;
}

fn tryMain(mpv: *c.mpv_handle) !void {
    var skipped_chapter_ids = std.AutoHashMap(usize, void).init(std.heap.c_allocator);
    defer skipped_chapter_ids.deinit();

    try ffi.checkMpvError(c.mpv_observe_property(mpv, 0, "chapter", c.MPV_FORMAT_INT64));

    std.log.info("loaded with client name '{s}'", .{c.mpv_client_name(mpv)});

    while (true) {
        const ev = @as(*c.mpv_event, c.mpv_wait_event(mpv, -1));
        try ffi.checkMpvError(ev.@"error");
        switch (ev.event_id) {
            c.MPV_EVENT_PROPERTY_CHANGE => {
                const evprop: *c.mpv_event_property = @ptrCast(@alignCast(ev.data));
                if (std.mem.eql(u8, "chapter", std.mem.span(evprop.name))) {
                    const chapter_id_ptr = @as(?*i64, @ptrCast(@alignCast(evprop.data)));
                    if (chapter_id_ptr) |chptr|
                        try onChapterChange(mpv, @intCast(chptr.*), &skipped_chapter_ids);
                }
            },
            c.MPV_EVENT_FILE_LOADED => skipped_chapter_ids.clearRetainingCapacity(),
            c.MPV_EVENT_SHUTDOWN => break,
            else => {},
        }
    }
}

fn msg(mpv: *c.mpv_handle, comptime fmt: []const u8, args: anytype) !void {
    std.log.info(fmt, args);

    var buf: [1024 * 4]u8 = undefined;
    const osd_msg = try std.fmt.bufPrintZ(&buf, "[sbskip] " ++ fmt, args);
    try ffi.checkMpvError(c.mpv_command(
        mpv,
        @constCast(&[_:null]?[*:0]const u8{ "show-text", osd_msg, "4000" }),
    ));
}

fn onChapterChange(
    mpv: *c.mpv_handle,
    chapter_id: usize,
    skipped: *std.AutoHashMap(usize, void),
) !void {
    if (skipped.contains(chapter_id))
        return;

    // fuck these ubiquitous duck typing implementations everywhere! we have structs, for fuck's sake!
    var chapter_list_node: c.mpv_node = undefined;
    try ffi.checkMpvError(c.mpv_get_property(
        mpv,
        "chapter-list",
        c.MPV_FORMAT_NODE,
        &chapter_list_node,
    ));
    defer c.mpv_free_node_contents(&chapter_list_node);
    std.debug.assert(chapter_list_node.format == c.MPV_FORMAT_NODE_ARRAY);

    const chapter_nodes = chapter_list_node.u.list.*.values[0..@intCast(chapter_list_node.u.list.*.num)];

    std.debug.assert(chapter_nodes[chapter_id].format == c.MPV_FORMAT_NODE_MAP);
    const chapter = Chapter.fromNodeMap(chapter_nodes[chapter_id].u.list.*);

    if (chapter.skipReason()) |reason| {
        const end_time = if (chapter_id != chapter_nodes.len - 1) end_time: {
            std.debug.assert(chapter_nodes[chapter_id + 1].format == c.MPV_FORMAT_NODE_MAP);
            const next_chapter = Chapter.fromNodeMap(chapter_nodes[chapter_id + 1].u.list.*);
            break :end_time next_chapter.time;
        } else end_time: {
            var end_time: f64 = 0.0;
            try ffi.checkMpvError(c.mpv_get_property(
                mpv,
                "duration",
                c.MPV_FORMAT_DOUBLE,
                &end_time,
            ));
            break :end_time end_time;
        };
        try ffi.checkMpvError(c.mpv_set_property(
            mpv,
            "time-pos",
            c.MPV_FORMAT_DOUBLE,
            @constCast(&end_time),
        ));
        try skipped.put(chapter_id, {});
        try msg(mpv, "skipped: {s}", .{reason});
    }
}

const Chapter = struct {
    title: [:0]const u8,
    time: f64,

    fn fromNodeMap(m: c.mpv_node_list) Chapter {
        var self = Chapter{ .title = "", .time = 0 };

        for (m.keys[0..@intCast(m.num)], m.values[0..@intCast(m.num)]) |k_c, v| {
            const k = std.mem.span(k_c);
            if (std.mem.eql(u8, k, "title")) {
                std.debug.assert(v.format == c.MPV_FORMAT_STRING);
                self.title = std.mem.span(v.u.string);
            } else if (std.mem.eql(u8, k, "time")) {
                std.debug.assert(v.format == c.MPV_FORMAT_DOUBLE);
                self.time = v.u.double_;
            }
        }

        return self;
    }

    /// Returns the reason for the chapter being skipped or null if the chapter should not be skipped.
    fn skipReason(self: Chapter) ?[]const u8 {
        const prefix = "[SponsorBlock]: ";
        if (self.title.len <= prefix.len or !std.mem.startsWith(u8, self.title, prefix))
            return null;

        const types = self.title[prefix.len..];
        var type_iter = std.mem.tokenize(u8, types, ",");
        while (type_iter.next()) |type_split| {
            const typestr = std.mem.trim(u8, type_split, &std.ascii.whitespace);
            if (blacklist.has(typestr))
                return typestr;
        }

        return null;
    }
};
