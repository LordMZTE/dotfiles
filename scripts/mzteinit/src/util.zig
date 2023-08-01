const std = @import("std");
const at = @import("ansi-term");

pub const ansi_clear = "\x1b[2J\x1b[1;1H";

pub const ExitMode = enum { run, immediate, delayed };

pub inline fn updateStyle(writer: anytype, current: *?at.style.Style, new: at.style.Style) !void {
    try at.format.updateStyle(writer, new, current.*);
    current.* = new;
}

fn formatCommand(
    cmd: []const []const u8,
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    _ = options;
    _ = fmt;

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
            try writer.print("{}", .{std.fmt.fmtSliceEscapeUpper(arg)});
            try writer.writeByte('\'');
        } else {
            try writer.writeAll(arg);
        }
    }
}

pub fn fmtCommand(cmd: []const []const u8) std.fmt.Formatter(formatCommand) {
    return .{ .data = cmd };
}
