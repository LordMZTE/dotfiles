const std = @import("std");
const builtin = @import("builtin");
const at = @import("ansi-term");
const common = @import("common");

const env = @import("env.zig");
const command = @import("command.zig");
const util = @import("util.zig");

const Mutex = @import("mutex.zig").Mutex;
const Server = @import("sock/Server.zig");

const msg = @import("message.zig").msg;

pub const std_options = std.Options{
    .log_level = .debug,
    .logFn = common.logFn,
};

pub fn main(init: std.process.Init) void {
    if (createLogFile(init.io)) |logf| {
        common.log_file = .{ .io = init.io, .file = logf };
    } else |e| {
        std.log.warn("Couldn't create logfile: {}", .{e});
    }
    defer if (common.log_file) |lf| lf.file.close(init.io);

    tryMain(init) catch |e| {
        std.log.err("FATAL ERROR: {}", .{e});
        if (@errorReturnTrace()) |trace| {
            var buf: [1024 * 8]u8 = undefined;
            const trace_s = s: {
                var fbs = std.Io.Writer.fixed(&buf);
                std.debug.writeErrorReturnTrace(
                    trace,
                    .{ .writer = &fbs, .mode = .no_color },
                ) catch break :s null;
                break :s fbs.buffered();
            };

            if (trace_s) |s| {
                std.log.err("ERT: {s}", .{s});
            }
        }
        std.debug.print("Encountered fatal error (check log), starting emergency shell!\n", .{});

        @panic(@errorName(std.process.replace(init.io, .{
            .argv = &.{"/bin/sh"},
        })));
    };
}

fn tryMain(init: std.process.Init) !void {
    var stdout_f = std.Io.File.stdout();
    var stdout_buf: [1024]u8 = undefined;
    var stdout = stdout_f.writer(init.io, &stdout_buf);

    const alloc = init.gpa;

    var launch_cmd: ?[][]const u8 = null;
    defer if (launch_cmd) |cmd| alloc.free(cmd);

    if (init.minimal.args.vector.len >= 2) {
        if (!std.mem.eql(u8, std.mem.span(init.minimal.args.vector[1]), "cmd") or
            init.minimal.args.vector.len < 3)
            return error.InvalidCommand;

        launch_cmd = try alloc.alloc([]const u8, init.minimal.args.vector[2..].len);
        for (launch_cmd.?, init.minimal.args.vector[2..]) |*arg, arg_in| {
            arg.* = std.mem.span(arg_in);
        }
    }

    var env_map: Mutex(*std.process.Environ.Map) = .{
        .data = init.environ_map,
    };

    if (env_map.data.get("MZTEINIT")) |_| {
        try stdout.interface.writeAll("mzteinit running already, starting shell\n");
        try stdout.interface.flush();
        return std.process.replace(init.io, .{ .argv = launch_cmd orelse &.{"nu"} });
    } else {
        try env_map.data.put("MZTEINIT", "1");
    }

    if (try env.populateEnvironment(alloc, init.io, env_map.data)) {
        env.populateSysdaemonEnvironment(alloc, init.io, env_map.data) catch |e| {
            std.log.err("failed to set sysdaemon environment: {}", .{e});
        };
    }

    @import("keyring.zig").linkUserKeyring() catch |e|
        std.log.err("failed to link user keyring: {} ", .{e});

    var srv: ?Server = null;
    var srv_future: ?std.Io.Future(Server.RunError!void) = null;
    if (env_map.data.get("XDG_RUNTIME_DIR")) |xrd| {
        var sockaddr_buf: [std.fs.max_path_bytes]u8 = undefined;
        const sockaddr = try std.fmt.bufPrintZ(
            &sockaddr_buf,
            "{s}/mzteinit-{}-{}.sock",
            .{ xrd, std.os.linux.getuid(), std.os.linux.getpid() },
        );

        try msg("starting socket server @ {s}...", .{sockaddr});

        srv = try Server.init(alloc, init.io, sockaddr, &env_map);
        errdefer srv.?.ss.deinit(init.io);
        srv_future = try init.io.concurrent(Server.run, .{&srv.?});
        errdefer srv_future.?.cancel(init.io) catch {};

        std.log.info("socket server started @ {s}", .{sockaddr});

        try env_map.mtx.lock(init.io);
        defer env_map.mtx.unlock(init.io);

        try env_map.data.put("MZTEINIT_SOCKET", sockaddr);
    } else {
        std.log.warn("XDG_RUNTIME_DIR is not set, no socket server will be started!", .{});
    }
    defer if (srv) |*s| s.ss.deinit(init.io);
    defer if (srv_future) |*fut| fut.cancel(init.io) catch {};

    if (launch_cmd) |cmd| {
        try msg("using launch command", .{});
        var child = spawn: {
            try env_map.mtx.lock(init.io);
            defer env_map.mtx.unlock(init.io);
            break :spawn try std.process.spawn(init.io, .{ .argv = cmd, .environ_map = env_map.data });
        };

        _ = try child.wait(init.io);
        return;
    }

    const entries_config_path = try std.fs.path.join(alloc, &.{
        env_map.data.get("XDG_CONFIG_HOME") orelse @panic("bork"),
        "mzteinit",
        "entries.cfg",
    });
    defer alloc.free(entries_config_path);

    std.log.info("entries file: {s}", .{entries_config_path});

    var entries_config_file = try std.Io.Dir.cwd().openFile(init.io, entries_config_path, .{});
    defer entries_config_file.close(init.io);

    var entries_config_reader = entries_config_file.reader(init.io, &.{});
    const entries_config_data = try entries_config_reader.interface.allocRemaining(alloc, .unlimited);
    defer alloc.free(entries_config_data);

    const entries = try command.parseEntriesConfig(alloc, entries_config_data);
    defer {
        for (entries) |entry|
            entry.deinit(alloc);
        alloc.free(entries);
    }

    while (true) {
        try stdout.interface.writeAll(util.ansi_clear);

        const cmd = ui(init.io, &stdout.interface, entries) catch |e| {
            std.debug.print("Error rendering the UI: {}\n", .{e});
            return e;
        };

        try stdout.interface.writeAll(util.ansi_clear);
        try stdout.interface.flush();

        var exit = util.ExitMode.run;
        cmd.run(init.io, &exit, &env_map) catch |e| {
            try stdout.interface.print("Error running command: {}\n\n", .{e});
            continue;
        };

        switch (exit) {
            .run => {},
            .immediate => return,
            .delayed => {
                try stdout.interface.writeAll("Goodbye!\n");
                try stdout.interface.flush();
                try init.io.sleep(.fromSeconds(2), .awake);
                return;
            },
        }
    }
}

fn ui(io: std.Io, w: *std.Io.Writer, entries: []command.Command) !command.Command {
    var style: ?at.style.Style = null;

    try @import("figlet.zig").writeFiglet(w);
    const uname = std.posix.uname();
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

    for (entries) |entry| {
        try updateStyle(w, .{ .foreground = .Cyan }, &style);
        try w.print("[{c}] ", .{entry.key});
        try updateStyle(w, .{ .foreground = .Green }, &style);
        try w.print("{s}\n", .{entry.label});
    }
    try updateStyle(w, .{
        .foreground = .Red,
        .font_style = .{ .bold = true },
    }, &style);
    try w.writeAll("\n[#] EMERGENCY SHELL\n");
    try at.format.resetStyle(w);
    style = .{};

    try w.flush();

    const old_termios = try std.posix.tcgetattr(std.posix.STDIN_FILENO);
    var new_termios = old_termios;
    new_termios.lflag.ICANON = false; // No line buffering
    new_termios.lflag.ECHO = false; // No echoing stuff
    try std.posix.tcsetattr(std.posix.STDIN_FILENO, .NOW, new_termios);

    var cmd: ?command.Command = null;
    var c: [1]u8 = undefined;
    while (cmd == null) {
        var reader = std.Io.File.stdin().readerStreaming(io, &c);
        try reader.interface.fill(1);
        if (c[0] == '#') {
            return error.ManualEmergency;
        }

        const key_upper = std.ascii.toUpper(c[0]);
        for (entries) |entry| {
            if (entry.key == key_upper) {
                cmd = entry;
                break;
            }
        } else {
            try w.print("Unknown command '{s}'\n", .{c});
            try w.flush();
        }
    }
    try std.posix.tcsetattr(std.posix.STDIN_FILENO, .NOW, old_termios);

    return cmd.?;
}

fn createLogFile(io: std.Io) !std.Io.File {
    var fname_buf: [128]u8 = undefined;
    const fname = try std.fmt.bufPrintZ(
        &fname_buf,
        "/tmp/mzteinit-{}-{}.log",
        .{ std.os.linux.getuid(), std.os.linux.getpid() },
    );
    return try std.Io.Dir.createFileAbsolute(io, fname, .{});
}

fn updateStyle(
    writer: anytype,
    new_style: at.style.Style,
    old_style: *?at.style.Style,
) !void {
    try at.format.updateStyle(writer, new_style, old_style.*);
    old_style.* = new_style;
}
