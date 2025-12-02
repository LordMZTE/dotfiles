const std = @import("std");
const c = ffi.c;

const ffi = @import("../ffi.zig");
const util = @import("../util.zig");

const log = std.log.scoped(.@"screenshot-open");

const ScreenshotOpen = @This();

tmpfiles: std.ArrayList([:0]const u8),

pub fn create() ScreenshotOpen {
    return .{ .tmpfiles = .empty };
}

pub fn setup(self: *ScreenshotOpen, mpv: *c.mpv_handle) !void {
    _ = self;
    _ = mpv;
}

pub fn deinit(self: *ScreenshotOpen) void {
    if (self.tmpfiles.capacity == 0) return;
    log.info("deleting {} temporary screenshot(s)", .{self.tmpfiles.items.len});
    for (self.tmpfiles.items) |path| {
        std.fs.deleteFileAbsoluteZ(path) catch |e| log.warn("couldn't delete {s}: {}", .{ path, e });
        std.heap.c_allocator.free(path);
    }
    self.tmpfiles.deinit(std.heap.c_allocator);
}

pub fn onEvent(self: *ScreenshotOpen, mpv: *c.mpv_handle, ev: *c.mpv_event) !void {
    switch (ev.event_id) {
        c.MPV_EVENT_CLIENT_MESSAGE => {
            const cmsg: *c.mpv_event_client_message = @ptrCast(@alignCast(ev.data));
            const args = cmsg.args[0..@intCast(cmsg.num_args)];
            std.debug.assert(std.mem.span(args[2]).len >= 3);

            if (args.len >= 3 and
                std.mem.orderZ(u8, args[0], "key-binding") == .eq and
                std.mem.orderZ(u8, args[1], "mzte-screenshot-open") == .eq and
                (args[2][0] == 'd' or args[2][0] == 'p') // key was pressed
            ) try self.screenshotOpen(mpv);
        },
        else => {},
    }
}

fn screenshotOpen(self: *ScreenshotOpen, mpv: *c.mpv_handle) !void {
    const tmpf_path = try std.fmt.allocPrintSentinel(
        std.heap.c_allocator,
        "/tmp/mzte-mpv-screenshot-{}-{}.jpg",
        .{ std.os.linux.getuid(), @rem(std.time.milliTimestamp(), std.time.ms_per_day) },
        0,
    );
    errdefer std.heap.c_allocator.free(tmpf_path);

    try ffi.checkMpvError(c.mpv_command(
        mpv,
        @constCast(&[_:null]?[*]const u8{ "screenshot-to-file", tmpf_path.ptr }),
    ));

    if (try std.posix.fork() == 0) {
        // NOTE: technically a race condition as, by some very abnormal events, tmpf_path could
        // theoretically be freed before the memcpy here. Meh.
        var fname_buf: [std.fs.max_path_bytes]u8 = undefined;
        @memcpy(fname_buf[0..tmpf_path.len], tmpf_path);
        fname_buf[tmpf_path.len] = 0;

        const err = std.posix.execvpeZ("swayimg", &.{ "swayimg", @ptrCast(&fname_buf) }, std.c.environ);
        log.err("spawning child: {}", .{err});
        std.process.exit(1);
    }

    try self.tmpfiles.append(std.heap.c_allocator, tmpf_path);
}
