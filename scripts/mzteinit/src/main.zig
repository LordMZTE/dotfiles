const std = @import("std");
const at = @import("ansi-term");
const env = @import("env.zig");
const run = @import("run.zig");
const util = @import("util.zig");

pub fn main() !void {
    var stdout = std.io.bufferedWriter(std.io.getStdOut().writer());
    var exit = false;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var env_map = std.process.EnvMap.init(alloc);
    defer env_map.deinit();

    for (std.os.environ) |env_var| {
        var idx: usize = 0;
        while (env_var[idx] != '=') {
            idx += 1;
        }

        const eq_idx = idx;

        while (env_var[idx] != 0) {
            idx += 1;
        }

        const key = env_var[0..eq_idx];
        const value = env_var[eq_idx + 1..idx];

        try env_map.put(key, value);
    }

    if (env_map.get("MZTEINIT")) |_| {
        try stdout.writer().writeAll("mzteinit running already, starting shell\n");
        try stdout.flush();
        var child = std.ChildProcess.init(&.{"fish"}, alloc);
        _ = try child.spawnAndWait();
        return;
    } else {
        try env_map.put("MZTEINIT", "1");
    }

    try env.populateEnvironment(&env_map);

    while (true) {
        try util.writeAnsiClear(stdout.writer());

        const cmd = ui(&stdout) catch |e| {
            std.debug.print("Error rendering the UI: {}\n", .{e});
            break;
        };

        try util.writeAnsiClear(stdout.writer());
        try stdout.flush();

        cmd.run(alloc, &exit, &env_map) catch |e| {
            try stdout.writer().print("Error running command: {}\n\n", .{e});
            continue;
        };

        if (exit) {
            try stdout.writer().writeAll("Goodbye!");
            try stdout.flush();
            std.time.sleep(2 * std.time.ns_per_s);
            return;
        }
    }
}

fn ui(buf_writer: anytype) !run.Command {
    const w = buf_writer.writer();
    var style: ?at.style.Style = null;

    try @import("figlet.zig").writeFiglet(w);
    const uname = std.os.uname();
    try updateStyle(w, .{ .foreground = .Yellow }, &style);
    try w.print(
        "\n {s} {s} {s}\n\n",
        .{
            uname.nodename,
            uname.release,
            uname.machine,
        },
    );

    try updateStyle(w, .{ .font_style = .{ .bold = true } }, &style);
    try w.writeAll("     What do you want to do?\n\n");

    for (std.enums.values(run.Command)) |tag| {
        try updateStyle(w, .{ .foreground = .Cyan }, &style);
        try w.print("[{c}] ", .{tag.char()});
        try updateStyle(w, .{ .foreground = .Green }, &style);
        try w.print("{s}\n", .{@tagName(tag)});
    }
    try at.format.resetStyle(w);
    style = .{};

    try buf_writer.flush();

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
            try buf_writer.flush();
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
