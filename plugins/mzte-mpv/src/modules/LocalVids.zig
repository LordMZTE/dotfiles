const std = @import("std");
const c = ffi.c;
const opts = @import("opts");

const ffi = @import("../ffi.zig");
const util = @import("../util.zig");

const log = std.log.scoped(.@"local-vids");

const vids_dirname = ".mzte-vids";

const LocalVids = @This();

/// watch-later-dir previously to having changed it, or null if we've not modified it
old_watch_later: ?[*:0]u8,
vids_dir: ?[:0]u8,

/// If this is non-null, we will set the `path` property to this value in the on_load hook. This is
/// needed because we have to determine the actual path name for special files in
/// `on_before_start_file` (to determine the correct `watch-later-dir` which we must set there), but
/// can't set `path` there yet[1]. To work around this, we register an on_load hook as well and set
/// it there.
///
/// [1]: https://mpv.io/manual/stable/#command-interface-on-before-start-file
set_path_to: ?[:0]u8,

/// The last value `stream-open-filename` had. This is used by the deletion handler where we can't access the
/// property anymore.
last_stream_open_filename: ?[:0]u8,

pub fn create() LocalVids {
    return .{
        // initialized in setup
        .old_watch_later = null,
        .vids_dir = null,
        .set_path_to = null,
        .last_stream_open_filename = null,
    };
}

pub fn setup(self: *LocalVids, mpv: *c.mpv_handle) !void {
    _ = self;
    _ = mpv;
    // FIXME: The property is already observed by LiveChat, avoid this jank
    //try ffi.checkMpvError(c.mpv_observe_property(
    //    mpv,
    //    0,
    //    "stream-open-filename",
    //    c.MPV_FORMAT_STRING,
    //));
}

pub fn deinit(self: *LocalVids) void {
    self.handleDeletionOnExit() catch |e| {
        log.err("deletion handler failed: {}", .{e});
    };

    if (self.old_watch_later) |o| c.mpv_free(o);
    if (self.vids_dir) |v| std.heap.c_allocator.free(v);
    if (self.set_path_to) |p| std.heap.c_allocator.free(p);
    if (self.last_stream_open_filename) |l| std.heap.c_allocator.free(l);
}

pub fn onEvent(self: *LocalVids, mpv: *c.mpv_handle, ev: *c.mpv_event) !void {
    switch (ev.event_id) {
        c.MPV_EVENT_HOOK => {
            // When we get an on_before_start_file hook, we check if we're playing a regular file and then find a
            // `dirname` dir.
            const hookev: *c.mpv_event_hook = @ptrCast(@alignCast(ev.data));
            if (std.mem.orderZ(u8, hookev.name, "on_before_start_file") == .eq) {
                try self.onBeforeStartFile(mpv);
            } else if (std.mem.orderZ(u8, hookev.name, "on_load") == .eq) {
                try self.onLoad(mpv);
            }
        },
        c.MPV_EVENT_PROPERTY_CHANGE => {
            const evprop: *c.mpv_event_property = @ptrCast(@alignCast(ev.data));
            if (std.mem.orderZ(u8, evprop.name, "stream-open-filename") == .eq) {
                const path = std.mem.span(
                    (@as(?*[*:0]const u8, @ptrCast(@alignCast(evprop.data))) orelse return).*,
                );

                if (self.last_stream_open_filename) |l| std.heap.c_allocator.free(l);
                self.last_stream_open_filename = try std.heap.c_allocator.dupeZ(u8, path);
            }
        },
        else => {},
    }
}

fn onBeforeStartFile(self: *LocalVids, mpv: *c.mpv_handle) !void {
    var raw_filename_cstr: [*:0]const u8 = undefined;
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
            @ptrCast(&raw_filename_cstr),
        ));
    }
    defer c.mpv_free(@constCast(raw_filename_cstr));

    const raw_filename_span = std.mem.span(raw_filename_cstr);

    var filename_buf: [std.fs.max_path_bytes]u8 = undefined;
    const filename = try self.mapSpecialFile(raw_filename_span, &filename_buf);

    // Check if we changed the filename at all (shallow compare works because mapSpecialFile returns
    // the parameter untouched).
    if (filename.ptr != raw_filename_span.ptr) {
        // MPV will invoke on_load after each on_before_start_file, where out handler sets this back
        // to null. If it isn't null here, something's awry.
        std.debug.assert(self.set_path_to == null);

        // Save it so we can set it in on_load.
        self.set_path_to = try std.heap.c_allocator.dupeZ(u8, filename);
    }

    // Only handle regular files.
    if (!util.pathIsRegularFile(filename)) {
        try self.resetWatchLater(mpv);
        return;
    }

    var path_buf: [std.fs.max_path_bytes]u8 = undefined;
    const path = std.fs.realpath(filename, &path_buf) catch |e| {
        log.warn("couldn't resolve filename '{s}': {}", .{ filename, e });
        return;
    };

    var dir = std.fs.path.dirname(path) orelse ".";
    var subpath_buf: [std.fs.max_path_bytes]u8 = undefined;

    // find vids dir
    while (true) {
        const guess = try std.fmt.bufPrintZ(&subpath_buf, "{s}/" ++ vids_dirname, .{dir});
        if (std.fs.cwd().statFile(guess)) |_| {
            if (self.vids_dir) |v| std.heap.c_allocator.free(v);
            self.vids_dir = try std.heap.c_allocator.dupeZ(u8, guess);
            break;
        } else |e| {
            switch (e) {
                error.FileNotFound, error.AccessDenied => {},
                else => return e,
            }

            dir = std.fs.path.dirname(dir) orelse {
                // no vids dir, remove it from state
                if (self.vids_dir) |v| std.heap.c_allocator.free(v);
                self.vids_dir = null;
                break;
            };
        }
    }

    if (self.vids_dir) |v| {
        const d = try std.fmt.bufPrintZ(&path_buf, "{s}/watch_later", .{v});
        log.info("using local watch-later-dir @ {s}", .{d});

        if (self.old_watch_later) |o| c.mpv_free(o);
        self.old_watch_later = null;
        try ffi.checkMpvError(c.mpv_get_property(
            mpv,
            "watch-later-dir",
            c.MPV_FORMAT_STRING,
            // ptrCast needed due to double pointer
            @ptrCast(&self.old_watch_later),
        ));

        try ffi.checkMpvError(c.mpv_set_property(
            mpv,
            "watch-later-dir",
            c.MPV_FORMAT_STRING,
            @ptrCast(@constCast(&d.ptr)),
        ));
    } else try self.resetWatchLater(mpv);
}

fn onLoad(self: *LocalVids, mpv: *c.mpv_handle) !void {
    // Check if we have a value to set `path` to
    if (self.set_path_to) |new_path| {
        defer {
            std.heap.c_allocator.free(new_path);
            self.set_path_to = null;
        }

        try ffi.checkMpvError(c.mpv_set_property_string(
            mpv,
            "stream-open-filename",
            new_path,
        ));
    }
}

fn handleDeletionOnExit(self: *LocalVids) !void {
    // If we're not in a vids dir or don't know a path, we don't ask the user if they want to delete
    // the file.
    if (self.vids_dir == null or self.last_stream_open_filename == null) return;

    if (try promptForDeletion(self.last_stream_open_filename.?)) {
        try std.io.getStdOut().writer().print("deleting: '{s}'\n", .{self.last_stream_open_filename.?});
        try std.fs.cwd().deleteFile(self.last_stream_open_filename.?);

        // Also delete the live_chat file from yt-dlp if present
        if (std.mem.lastIndexOfScalar(u8, self.last_stream_open_filename.?, '.')) |dot_idx| {
            var fname_buf: [std.fs.max_path_bytes]u8 = undefined;
            const livechat_fname = try std.fmt.bufPrintZ(
                &fname_buf,
                "{s}.live_chat.json",
                .{self.last_stream_open_filename.?[0..dot_idx]},
            );

            std.fs.cwd().deleteFile(livechat_fname) catch |e| switch (e) {
                error.FileNotFound => {},
                else => return e,
            };
        }
    }
}

fn resetWatchLater(self: *LocalVids, mpv: *c.mpv_handle) !void {
    if (self.old_watch_later) |o| {
        log.info("restoring old watch-later-dir", .{});
        try ffi.checkMpvError(c.mpv_set_property_string(
            mpv,
            "watch-later-dir",
            self.old_watch_later,
        ));
        c.mpv_free(o);
        self.old_watch_later = null;
    }
}

fn mapSpecialFile(self: *LocalVids, raw_filename: [:0]const u8, ret_buf: []u8) ![]const u8 {
    _ = self;
    if (std.mem.eql(u8, raw_filename, "!rand")) {
        var files: std.ArrayListUnmanaged([]const u8) = .empty;
        defer {
            for (files.items) |file| {
                std.heap.c_allocator.free(file);
            }
            files.deinit(std.heap.c_allocator);
        }

        // 1. Collect all regular files in CWD into a list
        try collectFilesInCWD(&files);

        if (files.items.len == 0) {
            log.err("Random file was requested but directory is empty!", .{});
            return raw_filename; // TODO: better way to handle this
        }

        // 2. Pick a random one
        const idx = std.crypto.random.uintLessThan(usize, files.items.len);
        const file = files.items[idx];

        log.info("chose random file '{s}'", .{file});

        @memcpy(ret_buf[0..file.len], file);
        return ret_buf[0..file.len];
    }

    if (std.mem.eql(u8, raw_filename, "!next")) {
        var files: std.ArrayListUnmanaged([]const u8) = .empty;
        defer {
            for (files.items) |file| {
                std.heap.c_allocator.free(file);
            }
            files.deinit(std.heap.c_allocator);
        }

        // 1. Collect all regular files in CWD into a list
        try collectFilesInCWD(&files);

        const file = std.sort.min([]const u8, files.items, {}, fnameLessThanByIdx) orelse {
            log.err("Next file was requested but directory is empty!", .{});
            return raw_filename; // TODO: better way to handle this
        };

        log.info("chose next file '{s}'", .{file});

        @memcpy(ret_buf[0..file.len], file);
        return ret_buf[0..file.len];
    }

    return raw_filename;
}

fn collectFilesInCWD(into: *std.ArrayListUnmanaged([]const u8)) !void {
    var cur_dir = try std.fs.cwd().openDir(".", .{ .iterate = true });
    defer cur_dir.close();
    var iter = cur_dir.iterate();
    while (try iter.next()) |ent| {
        if (ent.kind != .file) continue;

        // filter out yt-dlp live chat
        if (std.mem.endsWith(u8, ent.name, ".live_chat.json")) continue;

        const path_alloc = try std.heap.c_allocator.dupe(u8, ent.name);
        errdefer std.heap.c_allocator.free(path_alloc);
        try into.append(std.heap.c_allocator, path_alloc);
    }
}

/// Tries to extract the episode number from a given filename, null if there is none.
fn findIndexInFileName(fname: []const u8) ?usize {
    std.debug.assert(fname.len > 0);

    // End index of the last number in the file name, start will be i.
    // (last because the first number often indicates some number of the series as a whole)
    var end_idx: usize = 0;

    var i = fname.len;
    while (true) {
        i -= 1;

        if (std.ascii.isDigit(fname[i])) {
            end_idx = i;
            break;
        }

        // Search unsuccessful, no number in filename
        if (i == 0) return null;
    }

    while (std.ascii.isDigit(fname[i]) and i > 0) {
        i -= 1;
    }

    // We know that everything in our range is a digit, so if this fails, the number is huge (WTF)
    return std.fmt.parseInt(usize, fname[i..end_idx], 10) catch null;
}

fn fnameLessThanByIdx(_: void, a: []const u8, b: []const u8) bool {
    const idx_a = findIndexInFileName(a);
    const idx_b = findIndexInFileName(b);

    if (idx_a != null and idx_b != null) {
        return idx_a.? < idx_b.?;
    }

    // If b is null, we treat a as smaller
    if (idx_a) |_| return true;

    // analogous
    if (idx_b) |_| return false;

    return false; // both null
}

fn promptForDeletion(file: []const u8) !bool {
    try std.io.getStdOut().writer().print("delete file '{s}'? [Y/N] ", .{file});

    const old_termios = try std.posix.tcgetattr(std.posix.STDIN_FILENO);
    var new_termios = old_termios;
    new_termios.lflag.ICANON = false; // No line buffering
    try std.posix.tcsetattr(std.posix.STDIN_FILENO, .NOW, new_termios);
    defer std.posix.tcsetattr(std.posix.STDIN_FILENO, .NOW, old_termios) catch {};

    const answer = try std.io.getStdIn().reader().readByte();
    const ret = switch (answer) {
        'y', 'Y' => true,
        else => false,
    };

    try std.io.getStdOut().writeAll("\n");
    return ret;
}
