const std = @import("std");
const c = ffi.c;

const ffi = @import("../ffi.zig");
const util = @import("../util.zig");

const log = std.log.scoped(.@"sb-skip");

const ChapterSet = std.AutoHashMap(isize, void);

skipped_chapters: ChapterSet,

const SBSkip = @This();

const blacklist = std.StaticStringMap(void).initComptime(.{
    .{ "Endcards/Credits", {} },
    .{ "Interaction Reminder", {} },
    .{ "Intermission/Intro Animation", {} },
    .{ "Intro", {} },
    .{ "Outro", {} },
    .{ "Sponsor", {} },
    .{ "Unpaid/Self Promotion", {} },
});

pub fn onEvent(self: *SBSkip, mpv: *c.mpv_handle, ev: *c.mpv_event) !void {
    switch (ev.event_id) {
        c.MPV_EVENT_PROPERTY_CHANGE => {
            const evprop: *c.mpv_event_property = @ptrCast(@alignCast(ev.data));
            if (std.mem.eql(u8, std.mem.span(evprop.name), "chapter")) {
                const chapter_id_ptr = @as(?*i64, @ptrCast(@alignCast(evprop.data)));
                if (chapter_id_ptr) |chptr|
                    try self.onChapterChange(mpv, @intCast(chptr.*));
            }
        },
        c.MPV_EVENT_FILE_LOADED => self.skipped_chapters.clearRetainingCapacity(),
        else => {},
    }
}

fn onChapterChange(
    self: *SBSkip,
    mpv: *c.mpv_handle,
    chapter_id: isize,
) !void {
    if (chapter_id < 0 or self.skipped_chapters.contains(chapter_id))
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

    std.debug.assert(chapter_nodes[@intCast(chapter_id)].format == c.MPV_FORMAT_NODE_MAP);
    const chapter = Chapter.fromNodeMap(chapter_nodes[@intCast(chapter_id)].u.list.*);

    if (chapter.skipReason()) |reason| {
        var start_time: f64 = 0.0;
        try ffi.checkMpvError(c.mpv_get_property(
            mpv,
            "time-pos",
            c.MPV_FORMAT_DOUBLE,
            &start_time,
        ));
        const end_time = if (chapter_id != chapter_nodes.len - 1) end_time: {
            std.debug.assert(chapter_nodes[@as(usize, @intCast(chapter_id)) + 1].format ==
                c.MPV_FORMAT_NODE_MAP);
            const next_chapter = Chapter.fromNodeMap(
                chapter_nodes[@as(usize, @intCast(chapter_id)) + 1].u.list.*,
            );
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
        try self.skipped_chapters.put(chapter_id, {});
        try util.msg(mpv, .@"sb-skip", "skipped: {s} ({d:.2}s)", .{
            reason,
            end_time - start_time,
        });
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

pub fn setup(self: *SBSkip, mpv: *c.mpv_handle) !void {
    _ = self;
    try ffi.checkMpvError(c.mpv_observe_property(mpv, 0, "chapter", c.MPV_FORMAT_INT64));
}

pub fn create() SBSkip {
    return .{
        .skipped_chapters = ChapterSet.init(std.heap.c_allocator),
    };
}

pub fn deinit(self: *SBSkip) void {
    self.skipped_chapters.deinit();
}
