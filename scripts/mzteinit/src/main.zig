const std = @import("std");
const at = @import("ansi-term");
const env = @import("env.zig");
const run = @import("run.zig");
const util = @import("util.zig");

const msg = @import("message.zig").msg;

pub const std_options = struct {
    pub const log_level = .debug;
    pub fn logFn(
        comptime msg_level: std.log.Level,
        comptime scope: @TypeOf(.enum_literal),
        comptime fmt: []const u8,
        args: anytype,
    ) void {
        const logfile = log_file orelse return;

        if (scope != .default) {
            logfile.writer().print("[{s}] ", .{@tagName(scope)}) catch return;
        }

        logfile.writer().writeAll(switch (msg_level) {
            .err => "E: ",
            .warn => "W: ",
            .info => "I: ",
            .debug => "D: ",
        }) catch return;

        logfile.writer().print(fmt ++ "\n", args) catch return;
    }
};

var log_file: ?std.fs.File = null;

pub fn main() void {
    log_file = createLogFile() catch null;
    defer if (log_file) |lf| lf.close();

    tryMain() catch |e| {
        std.log.err("FATAL ERROR: {}", .{e});
        std.debug.print("Encountered fatal error (check log), starting emergency shell!\n", .{});

        @panic(@errorName(std.os.execveZ(
            "/bin/sh",
            &[_:null]?[*:0]const u8{"/bin/sh"},
            &[_:null]?[*:0]const u8{},
        )));
    };
}

fn tryMain() !void {
    var stdout = std.io.bufferedWriter(std.io.getStdOut().writer());

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var launch_cmd: ?[][]const u8 = null;
    defer if (launch_cmd) |cmd| alloc.free(cmd);

    if (std.os.argv.len >= 2) {
        if (!std.mem.eql(u8, std.mem.span(std.os.argv[1]), "cmd") or std.os.argv.len < 3)
            return error.InvalidCommand;

        launch_cmd = try alloc.alloc([]const u8, std.os.argv[2..].len);
        for (launch_cmd.?, std.os.argv[2..]) |*arg, arg_in| {
            arg.* = std.mem.span(arg_in);
        }
    }
    
    var env_map = try std.process.getEnvMap(alloc);
    defer env_map.deinit();

    if (env_map.get("MZTEINIT")) |_| {
        try stdout.writer().writeAll("mzteinit running already, starting shell\n");
        try stdout.flush();
        var child = std.ChildProcess.init(launch_cmd orelse &.{"fish"}, alloc);
        _ = try child.spawnAndWait();
        return;
    } else {
        try env_map.put("MZTEINIT", "1");
    }

    if (try env.populateEnvironment(&env_map)) {
        try env.populateSysdaemonEnvironment(&env_map);
    }

    if (launch_cmd) |cmd| {
        try msg("using launch command", .{});
        var child = std.ChildProcess.init(cmd, alloc);
        _ = try child.spawnAndWait();
        return;
    }

    while (true) {
        try stdout.writer().writeAll(util.ansi_clear);

        const cmd = ui(&stdout) catch |e| {
            std.debug.print("Error rendering the UI: {}\n", .{e});
            break;
        };

        try stdout.writer().writeAll(util.ansi_clear);
        try stdout.flush();

        var exit = util.ExitMode.run;
        cmd.run(alloc, &exit, &env_map) catch |e| {
            try stdout.writer().print("Error running command: {}\n\n", .{e});
            continue;
        };

        switch (exit) {
            .run => {},
            .immediate => return,
            .delayed => {
                try stdout.writer().writeAll("Goodbye!");
                try stdout.flush();
                std.time.sleep(2 * std.time.ns_per_s);
                return;
            },
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

fn createLogFile() !std.fs.File {
    var fname_buf: [128]u8 = undefined;
    const fname = try std.fmt.bufPrintZ(
        &fname_buf,
        "/tmp/mzteinit-{}-{}.log",
        .{ std.os.linux.getuid(), std.os.linux.getpid() },
    );
    return try std.fs.createFileAbsoluteZ(fname, .{});
}

fn updateStyle(
    writer: anytype,
    new_style: at.style.Style,
    old_style: *?at.style.Style,
) !void {
    try at.format.updateStyle(writer, new_style, old_style.*);
    old_style.* = new_style;
}
