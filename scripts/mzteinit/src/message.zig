const std = @import("std");
const at = @import("ansi-term");

const util = @import("util.zig");

pub fn msg(comptime fmt: []const u8, args: anytype) !void {
    var buf: [512]u8 = undefined;
    var writer = std.fs.File.stdout().writer(&buf);

    var style: ?at.style.Style = null;

    try util.updateStyle(&writer.interface, &style, .{ .font_style = .{ .bold = true } });
    try writer.interface.writeByte('[');
    try util.updateStyle(&writer.interface, &style, .{ .font_style = .{ .bold = true }, .foreground = .Red });
    try writer.interface.writeAll(" MZTEINIT ");
    try util.updateStyle(&writer.interface, &style, .{ .font_style = .{ .bold = true } });
    try writer.interface.writeByte(']');
    try util.updateStyle(&writer.interface, &style, .{ .foreground = .Cyan });

    try writer.interface.print(" " ++ fmt ++ "\n", args);

    try util.updateStyle(&writer.interface, &style, .{});
}
