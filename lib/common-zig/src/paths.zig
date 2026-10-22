const std = @import("std");

pub fn bufJoinZ(buf: []u8, paths: []const []const u8) ![:0]u8 {
    return try std.mem.printSentinel(buf, "{f}", .{std.fs.path.fmtJoin(paths)}, 0);
}
