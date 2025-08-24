const std = @import("std");

pub fn command(cmd: []const []const u8) std.fmt.Alt([]const []const u8, commandFn) {
    return .{ .data = cmd };
}

fn commandFn(
    cmd: []const []const u8,
    writer: *std.Io.Writer,
) !void {
    var first = true;
    for (cmd) |arg| {
        defer first = false;
        var needs_quote = false;
        for (arg) |ch| {
            if (!std.ascii.isPrint(ch) or ch == '"' or ch == ' ' or ch == '*' or ch == '$') {
                needs_quote = true;
                break;
            }
        }

        if (!first)
            try writer.writeByte(' ');

        if (needs_quote) {
            try writer.writeByte('\'');
            try writer.print("{f}", .{std.ascii.hexEscape(arg, .lower)});
            try writer.writeByte('\'');
        } else {
            try writer.writeAll(arg);
        }
    }
}
