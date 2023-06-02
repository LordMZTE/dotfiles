pub fn writeAnsiClear(writer: anytype) !void {
    try writer.writeAll("\x1b[2J\x1b[1;1H");
}

pub const ExitMode = enum { run, immediate, delayed };
