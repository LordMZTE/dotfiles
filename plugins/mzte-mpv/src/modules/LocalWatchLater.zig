const std = @import("std");
const c = ffi.c;
const opts = @import("opts");

const ffi = @import("../ffi.zig");
const util = @import("../util.zig");

const log = std.log.scoped(.@"local-watch-later");

const dirname = ".mzte-watch-later";

const LocalWatchLater = @This();

old_watch_later: [*:0]u8,
touched_watch_later: bool,

pub fn create() LocalWatchLater {
    return .{
        // initialized in setup
        .old_watch_later = undefined,
        .touched_watch_later = false,
    };
}

pub fn setup(self: *LocalWatchLater, mpv: *c.mpv_handle) !void {
    try ffi.checkMpvError(c.mpv_get_property(
        mpv,
        "watch-later-dir",
        c.MPV_FORMAT_STRING,
        // ptrCast needed due to double pointer
        @ptrCast(&self.old_watch_later),
    ));
}

pub fn deinit(self: *LocalWatchLater) void {
    c.mpv_free(self.old_watch_later);
}

pub fn onEvent(self: *LocalWatchLater, mpv: *c.mpv_handle, ev: *c.mpv_event) !void {
    switch (ev.event_id) {
        c.MPV_EVENT_HOOK => {
            // When we get an on_load hook, we check if we're playing a regular file and then find a
            // `dirname` dir.
            const hookev: *c.mpv_event_hook = @ptrCast(@alignCast(ev.data));
            if (std.mem.orderZ(u8, hookev.name, "on_before_start_file") == .eq) {
                try self.onLoad(mpv);
            }
        },
        else => {},
    }
}

fn onLoad(self: *LocalWatchLater, mpv: *c.mpv_handle) !void {
    var filename_cstr: [*:0]const u8 = undefined;
    {
        // Doesn't work because the `path` property won't be available here
        //try ffi.checkMpvError(c.mpv_get_property(
        //    mpv,
        //    "path",
        //    c.MPV_FORMAT_STRING,
        //    @ptrCast(&path_cstr),
        //));
        var pos: i64 = 0;
        try ffi.checkMpvError(c.mpv_get_property(
            mpv,
            "playlist-pos",
            c.MPV_FORMAT_INT64,
            &pos,
        ));
        var name_buf: [128]u8 = undefined;
        try ffi.checkMpvError(c.mpv_get_property(
            mpv,
            try std.fmt.bufPrintZ(&name_buf, "playlist/{}/filename", .{pos}),
            c.MPV_FORMAT_STRING,
            @ptrCast(&filename_cstr),
        ));
    }
    defer c.mpv_free(@constCast(filename_cstr));

    const filename_span = std.mem.span(filename_cstr);

    // Only handle regular files.
    if (!util.pathIsRegularFile(filename_span)) {
        try self.resetWatchLater(mpv);
        return;
    }

    var path_buf: [std.fs.max_path_bytes]u8 = undefined;
    const path = std.fs.realpath(filename_span, &path_buf) catch |e| {
        log.warn("couldn't resolve filename '{s}': {}", .{ filename_span, e });
        return;
    };

    var dir = std.fs.path.dirname(path) orelse ".";
    var subpath_buf: [std.fs.max_path_bytes]u8 = undefined;
    const watch_later_dir: ?[:0]const u8 = watchlaterdir: while (true) {
        const guess = try std.fmt.bufPrintZ(&subpath_buf, "{s}/" ++ dirname, .{dir});
        if (std.fs.cwd().statFile(guess)) |_| {
            break :watchlaterdir guess;
        } else |e| {
            switch (e) {
                error.FileNotFound, error.AccessDenied => {},
                else => return e,
            }

            dir = std.fs.path.dirname(dir) orelse break :watchlaterdir null;
        }
    };

    if (watch_later_dir) |d| {
        log.info("using local watch-later-dir @ {s}", .{d});
        try ffi.checkMpvError(c.mpv_set_property(
            mpv,
            "watch-later-dir",
            c.MPV_FORMAT_STRING,
            @ptrCast(@constCast(&d.ptr)),
        ));
        self.touched_watch_later = true;
    } else try self.resetWatchLater(mpv);
}

fn resetWatchLater(self: *LocalWatchLater, mpv: *c.mpv_handle) !void {
    if (!self.touched_watch_later) return;
    log.info("restoring old watch-later-dir", .{});
    try ffi.checkMpvError(c.mpv_set_property_string(
        mpv,
        "watch-later-dir",
        self.old_watch_later,
    ));
}
