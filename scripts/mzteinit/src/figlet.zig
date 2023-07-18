const std = @import("std");
const at = @import("ansi-term");

const util = @import("util.zig");

// r means switch to red
const figlet =
    \\        __                   __r__  ________ ____________
    \\       / /   ____  _________/ r/  |/  /__  //_  __/ ____/
    \\      / /   / __ \/ ___/ __  r/ /|_/ /  / /  / / / __/   
    \\     / /___/ /_/ / /  / /_/ r/ /  / /  / /__/ / / /___   
    \\    /_____/\____/_/   \__,_r/_/  /_/  /____/_/ /_____/   
;

pub fn writeFiglet(writer: anytype) !void {
    var style: ?at.style.Style = null;
    for (figlet) |char| {
        switch (char) {
            'r' => {
                try util.updateStyle(writer, &style, .{ .foreground = .Red });
            },
            '\n' => {
                try util.updateStyle(writer, &style, .{});
                try writer.writeByte('\n');
            },
            else => try writer.writeByte(char),
        }
    }
}
