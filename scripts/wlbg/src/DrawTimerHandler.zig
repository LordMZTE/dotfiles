const std = @import("std");
const xev = @import("xev");

const options = @import("options.zig");

loop: *xev.Loop,

/// Completion of the main redraw timer
completion: *xev.Completion,

/// Contains a bool for each output, true if needs redraw
should_redraw: []bool,

const DrawTimerHandler = @This();

pub fn nextAction(self: *DrawTimerHandler) xev.CallbackAction {
    for (self.should_redraw) |ro|
        if (ro) return .rearm;
    return .disarm;
}

pub fn maybeWake(self: *DrawTimerHandler) void {
    if (self.completion.flags.state == .dead and self.nextAction() == .rearm) {
        self.resetTimer();
        self.loop.add(self.completion);
    }
}

pub fn resetTimer(self: *DrawTimerHandler) void {
    const next_time = self.loop.now() + 1000 / options.fps;
    self.completion.op.timer.reset = .{
        .tv_sec = @divTrunc(next_time, std.time.ms_per_s),
        .tv_nsec = @mod(next_time, std.time.ms_per_s) * std.time.ns_per_ms,
    };
}

pub fn damage(self: *DrawTimerHandler, idx: usize) void {
    self.should_redraw[idx] = true;
    self.maybeWake();
}

