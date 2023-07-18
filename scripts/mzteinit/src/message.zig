const std = @import("std");
const at = @import("ansi-term");

const util = @import("util.zig");

pub fn msg(comptime fmt: []const u8, args: anytype) !void {
    const writer = std.io.getStdErr().writer();
    var style: ?at.style.Style = null;

    try util.updateStyle(writer, &style, .{ .font_style = .{ .bold = true } });
    try writer.writeByte('[');
    try util.updateStyle(writer, &style, .{ .font_style = .{ .bold = true }, .foreground = .Red });
    try writer.writeAll(" MZTEINIT ");
    try util.updateStyle(writer, &style, .{ .font_style = .{ .bold = true } });
    try writer.writeByte(']');
    try util.updateStyle(writer, &style, .{ .foreground = .Cyan });

    try std.fmt.format(writer, " " ++ fmt ++ "\n", args);

    try util.updateStyle(writer, &style, .{});
}
