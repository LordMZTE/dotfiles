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

pub fn main() void {
    common.log_file = createLogFile() catch null;
    defer if (common.log_file) |lf| lf.close();

    tryMain() catch |e| {
        std.log.err("FATAL ERROR: {}", .{e});
        if (@errorReturnTrace()) |trace| {
            var buf: [1024 * 8]u8 = undefined;
            const trace_s = s: {
                const deb_inf = std.debug.getSelfDebugInfo() catch break :s null;

                var fbs = std.Io.Writer.fixed(&buf);
                std.debug.writeStackTrace(
                    trace.*,
                    &fbs,
                    deb_inf,
                    .no_color,
                ) catch break :s null;
                break :s fbs.buffered();
            };

            if (trace_s) |s| {
                std.log.err("ERT: {s}", .{s});
            }
        }
        std.debug.print("Encountered fatal error (check log), starting emergency shell!\n", .{});

        @panic(@errorName(std.posix.execveZ(
            "/bin/sh",
            &[_:null]?[*:0]const u8{"/bin/sh"},
            &[_:null]?[*:0]const u8{},
        )));
    };
}

fn tryMain() !void {
    var stdout_f = std.fs.File.stdout();
    var stdout_buf: [1024]u8 = undefined;
    var stdout = stdout_f.writer(&stdout_buf);

    var dbg_alloc = if (builtin.mode == .Debug) std.heap.DebugAllocator(.{}){} else {};
    defer if (builtin.mode == .Debug) {
        _ = dbg_alloc.deinit();
    };

    const alloc = if (builtin.mode == .Debug) dbg_alloc.allocator() else std.heap.smp_allocator;

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

    var env_map = Mutex(std.process.EnvMap){
        .data = try std.process.getEnvMap(alloc),
    };
    defer env_map.data.deinit();

    if (env_map.data.get("MZTEINIT")) |_| {
        try stdout.interface.writeAll("mzteinit running already, starting shell\n");
        try stdout.interface.flush();
        var child = std.process.Child.init(launch_cmd orelse &.{"nu"}, alloc);
        _ = try child.spawnAndWait();
        return;
    } else {
        try env_map.data.put("MZTEINIT", "1");
    }

    if (try env.populateEnvironment(&env_map.data)) {
        env.populateSysdaemonEnvironment(&env_map.data) catch |e| {
            std.log.err("failed to set sysdaemon environment: {}", .{e});
        };
    }

    var srv: ?Server = null;
    if (env_map.data.get("XDG_RUNTIME_DIR")) |xrd| {
        var sockaddr_buf: [std.fs.max_path_bytes]u8 = undefined;
        const sockaddr = try std.fmt.bufPrintZ(
            &sockaddr_buf,
            "{s}/mzteinit-{}-{}.sock",
            .{ xrd, std.os.linux.getuid(), std.os.linux.getpid() },
        );

        try msg("starting socket server @ {s}...", .{sockaddr});

        srv = try Server.init(alloc, sockaddr, &env_map);
        errdefer srv.?.ss.deinit();
        (try std.Thread.spawn(.{}, Server.run, .{&srv.?})).detach();

        std.log.info("socket server started @ {s}", .{sockaddr});

        env_map.mtx.lock();
        defer env_map.mtx.unlock();

        try env_map.data.put("MZTEINIT_SOCKET", sockaddr);
    } else {
        std.log.warn("XDG_RUNTIME_DIR is not set, no socket server will be started!", .{});
    }
    defer if (srv) |*s| s.ss.deinit();

    if (launch_cmd) |cmd| {
        try msg("using launch command", .{});
        var child = std.process.Child.init(cmd, alloc);
        {
            env_map.mtx.lock();
            defer env_map.mtx.unlock();
            child.env_map = &env_map.data;
            try child.spawn();
        }
        _ = try child.wait();
        return;
    }

    const entries_config_path = try std.fs.path.join(alloc, &.{
        env_map.data.get("XDG_CONFIG_HOME") orelse @panic("bork"),
        "mzteinit",
        "entries.cfg",
    });
    defer alloc.free(entries_config_path);

    std.log.info("entries file: {s}", .{entries_config_path});

    var entries_config_file = try std.fs.cwd().openFile(entries_config_path, .{});
    defer entries_config_file.close();

    const entries_config_data = try entries_config_file.readToEndAlloc(alloc, std.math.maxInt(usize));
    defer alloc.free(entries_config_data);

    const entries = try command.parseEntriesConfig(alloc, entries_config_data);
    defer {
        for (entries) |entry|
            entry.deinit(alloc);
        alloc.free(entries);
    }

    while (true) {
        try stdout.interface.writeAll(util.ansi_clear);

        const cmd = ui(&stdout.interface, entries) catch |e| {
            std.debug.print("Error rendering the UI: {}\n", .{e});
            return e;
        };

        try stdout.interface.writeAll(util.ansi_clear);
        try stdout.interface.flush();

        var exit = util.ExitMode.run;
        cmd.run(alloc, &exit, &env_map) catch |e| {
            try stdout.interface.print("Error running command: {}\n\n", .{e});
            continue;
        };

        switch (exit) {
            .run => {},
            .immediate => return,
            .delayed => {
                try stdout.interface.writeAll("Goodbye!");
                try stdout.interface.flush();
                std.Thread.sleep(2 * std.time.ns_per_s);
                return;
            },
        }
    }
}

fn ui(w: *std.Io.Writer, entries: []command.Command) !command.Command {
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
        std.debug.assert(try std.fs.File.stdin().read(&c) == 1);
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
