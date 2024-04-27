const std = @import("std");
const at = @import("ansi-term");

pub const ViMode = enum {
    default,
    insert,
    replace_one,
    replace,
    visual,

    unknown,
    _none,

    pub fn parse(s: []const u8) ViMode {
        return std.meta.stringToEnum(ViMode, s) orelse .unknown;
    }

    /// Gets the color for the mode
    /// Caller asserts that self != .none
    pub fn getColor(self: ViMode) at.style.Color {
        return switch (self) {
            .default => .Yellow,
            .insert => .Green,
            .replace_one => .Magenta,
            .replace => .Blue,
            .visual => .Magenta,
            .unknown => .Red,
            ._none => unreachable,
        };
    }

    /// Gets a char to show for the mode.
    /// Caller asserts that self != .none
    pub fn getChar(self: ViMode) u8 {
        return switch (self) {
            .default => 'N',
            .insert => 'I',
            .replace_one, .replace => 'R',
            .visual => 'V',
            .unknown => '?',
            ._none => unreachable,
        };
    }
};
