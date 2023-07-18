const at = @import("ansi-term");

pub const ansi_clear = "\x1b[2J\x1b[1;1H";

pub const ExitMode = enum { run, immediate, delayed };

pub inline fn updateStyle(writer: anytype, current: *?at.style.Style, new: at.style.Style) !void {
    try at.format.updateStyle(writer, new, current.*);
    current.* = new;
}
