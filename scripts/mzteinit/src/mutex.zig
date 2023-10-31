const std = @import("std");

/// A version of std.Thread.Mutex that wraps some data.
pub fn Mutex(comptime T: type) type {
    return struct {
        data: T,
        mtx: std.Thread.Mutex = .{},
    };
}

