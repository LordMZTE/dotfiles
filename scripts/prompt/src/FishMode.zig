const std = @import("std");
const at = @import("ansi-term");

pub const Mode = enum {
    default,
    insert,
    replace_one,
    replace,
    visual,
    unknown,
};

mode: Mode,

const Self = @This();

pub fn parse(s: []const u8) Self {
    return .{ .mode = std.meta.stringToEnum(Mode, s) orelse .unknown };
}

/// Gets the color for the mode
pub fn getColor(self: *Self) at.style.Color {
    return switch (self.mode) {
        .default => .Yellow,
        .insert => .Green,
        .replace_one => .Magenta,
        .replace => .Blue,
        .visual => .Magenta,
        .unknown => .Red,
    };
}

/// Gets a string to show for the mode.
/// Returned string is static
pub fn getText(self: *Self) []const u8 {
    return switch (self.mode) {
        .default => "N",
        .insert => "I",
        .replace_one, .replace => "R",
        .visual => "V",
        .unknown => "?",
    };
}
