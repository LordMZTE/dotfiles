const std = @import("std");

pub fn bufJoinZ(buf: []u8, paths: []const []const u8) ![:0]u8 {
    return try std.fmt.bufPrintZ(buf, "{f}", .{std.fs.path.fmtJoin(paths)});
}
