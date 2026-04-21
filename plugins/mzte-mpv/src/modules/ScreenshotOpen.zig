const std = @import("std");
const c = @import("c");

const ffi = @import("../ffi.zig");
const util = @import("../util.zig");

const State = @import("../State.zig");

const log = std.log.scoped(.@"screenshot-open");

const ScreenshotOpen = @This();

tmpfiles: std.ArrayList([:0]const u8),

io: std.Io,

pub fn create(io: std.Io) ScreenshotOpen {
    return .{ .tmpfiles = .empty, .io = io };
}

pub fn setup(self: *ScreenshotOpen, mpv: *c.mpv_handle) !void {
    _ = self;
    _ = mpv;
}

pub fn deinit(self: *ScreenshotOpen) void {
    if (self.tmpfiles.capacity == 0) return;
    log.info("deleting {} temporary screenshot(s)", .{self.tmpfiles.items.len});
    for (self.tmpfiles.items) |path| {
        std.Io.Dir.deleteFileAbsolute(self.io, path) catch |e| log.warn("couldn't delete {s}: {}", .{ path, e });
        std.heap.c_allocator.free(path);
    }
    self.tmpfiles.deinit(std.heap.c_allocator);
}

pub fn onEvent(
    self: *ScreenshotOpen,
    mpv: *c.mpv_handle,
    io: std.Io,
    state: *State,
    ev: *c.mpv_event,
) !void {
    _ = io;
    switch (ev.event_id) {
        c.MPV_EVENT_CLIENT_MESSAGE => {
            const cmsg: *c.mpv_event_client_message = @ptrCast(@alignCast(ev.data));
            const args = cmsg.args[0..@intCast(cmsg.num_args)];
            std.debug.assert(std.mem.span(args[2]).len >= 3);

            if (args.len >= 3 and
                std.mem.orderZ(u8, args[0], "key-binding") == .eq and
                std.mem.orderZ(u8, args[1], "mzte-screenshot-open") == .eq and
                (args[2][0] == 'd' or args[2][0] == 'p') // key was pressed
            ) try self.screenshotOpen(mpv, state);
        },
        else => {},
    }
}

fn screenshotOpen(self: *ScreenshotOpen, mpv: *c.mpv_handle, state: *State) !void {
    const tmpf_path = try std.fmt.allocPrintSentinel(
        std.heap.c_allocator,
        "/tmp/mzte-mpv-screenshot-{}-{}.png",
        .{
            std.os.linux.getuid(),
            @rem(std.Io.Timestamp.now(self.io, .real).toMilliseconds(), std.time.ms_per_day),
        },
        0,
    );
    errdefer std.heap.c_allocator.free(tmpf_path);

    try ffi.checkMpvError(c.mpv_command(
        mpv,
        @constCast(&[_:null]?[*]const u8{ "screenshot-to-file", tmpf_path.ptr }),
    ));

    const child = try std.process.spawn(self.io, .{ .argv = &.{ "swayimg", tmpf_path } });
    try state.job_pool.concurrent(self.io, waitForChild, .{ self.io, child });

    try self.tmpfiles.append(std.heap.c_allocator, tmpf_path);
}

fn waitForChild(io: std.Io, child_const: std.process.Child) std.Io.Cancelable!void {
    var child = child_const;
    _ = child.wait(io) catch |e| switch (e) {
        error.Canceled => return error.Canceled,
        else => {
            log.warn("couldn't wait for child: {}", .{e});
            return;
        },
    };
}
