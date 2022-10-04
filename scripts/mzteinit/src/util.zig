pub fn writeAnsiClear(writer: anytype) !void {
    try writer.writeAll("\x1b[2J\x1b[1;1H");
}
