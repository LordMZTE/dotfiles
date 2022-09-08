const std = @import("std");
const at = @import("ansi-term");
const run = @import("run.zig");

pub fn main() !void {
    while (true) {
        try std.io.getStdOut().writeAll("\x1b[2J\x1b[1;1H"); // clear
        const cmd = ui() catch |e| {
            std.debug.print("Error rendering the UI: {}\n", .{e});
            break;
        };
        cmd.run() catch |e| {
            try std.io.getStdOut().writeAll("\x1b[2J\x1b[1;1H"); // clear
            std.debug.print("Error running command: {}\n", .{e});
        };
    }
}

fn ui() !run.Command {
    var stdout = std.io.bufferedWriter(std.io.getStdOut().writer());
    const w = stdout.writer();

    try @import("figlet.zig").writeFiglet(w);
    try w.writeAll(
        \\
        \\What do you want to do?
        \\
        \\
    );

    var style: ?at.style.Style = null;
    for (std.enums.values(run.Command)) |tag| {
        try updateStyle(w, .{ .foreground = .Cyan }, &style);
        try w.print("[{c}] ", .{tag.char()});
        try updateStyle(w, .{ .foreground = .Green }, &style);
        try w.print("{s}\n", .{@tagName(tag)});
    }
    try at.format.resetStyle(w);

    try stdout.flush();

    const old_termios = try std.os.tcgetattr(std.os.STDIN_FILENO);
    var new_termios = old_termios;
    new_termios.lflag &= ~std.os.linux.ICANON; // No line buffering
    new_termios.lflag &= ~std.os.linux.ECHO; // No echoing stuff
    try std.os.tcsetattr(std.os.STDIN_FILENO, .NOW, new_termios);

    var cmd: ?run.Command = null;
    var c: [1]u8 = undefined;
    while (cmd == null) {
        std.debug.assert(try std.io.getStdIn().read(&c) == 1);
        cmd = run.Command.fromChar(c[0]);
        if (cmd == null) {
            try w.print("Unknown command '{s}'\n", .{c});
            try stdout.flush();
        }
    }
    try std.os.tcsetattr(std.os.STDIN_FILENO, .NOW, old_termios);

    return cmd.?;
}

fn updateStyle(
    writer: anytype,
    new_style: at.style.Style,
    old_style: *?at.style.Style,
) !void {
    try at.format.updateStyle(writer, new_style, old_style.*);
    old_style.* = new_style;
}
