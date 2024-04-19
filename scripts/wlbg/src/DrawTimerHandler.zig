const std = @import("std");

const options = @import("options.zig");

timerfd: std.posix.fd_t,
timerfd_active: bool = false,

/// Contains a bool for each output, true if needs redraw
should_redraw: []bool,

const DrawTimerHandler = @This();

pub const timerspec: std.os.linux.itimerspec = spec: {
    const interval = 1000 / options.fps;

    break :spec .{
        .it_value = .{ .tv_sec = 0, .tv_nsec = 1 },
        .it_interval = .{
            .tv_sec = @divTrunc(interval, std.time.ms_per_s),
            .tv_nsec = @mod(interval, std.time.ms_per_s) * std.time.ns_per_ms,
        },
    };
};

pub fn shouldDisarm(self: *DrawTimerHandler) bool {
    for (self.should_redraw) |ro|
        if (ro) return false;
    return true;
}

pub fn maybeWake(self: *DrawTimerHandler) !void {
    if (!self.timerfd_active and !self.shouldDisarm()) {
        try std.posix.timerfd_settime(self.timerfd, .{}, &timerspec, null);
        self.timerfd_active = true;
    }
}

pub fn damage(self: *DrawTimerHandler, idx: usize) !void {
    self.should_redraw[idx] = true;
    try self.maybeWake();
}

pub fn damageAll(self: *DrawTimerHandler) !void {
    @memset(self.should_redraw, true);
    try self.maybeWake();
}
