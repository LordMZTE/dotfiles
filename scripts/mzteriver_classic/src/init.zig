const std = @import("std");
const opt = @import("cg");
const cgopts = @import("cgopts");

const common = @import("common");

const log = std.log.scoped(.init);

const Connection = @import("Connection.zig");

const journal_prefix = "systemd-cat --level-prefix=false -- ";

fn initCommand(comptime argv: []const [:0]const u8) []const [:0]const u8 {
    return &[_][:0]const u8{
        "systemd-cat",
        "--level-prefix=false",
        "--identifier=" ++ argv[0],
        "--",
    } ++ argv;
}

pub fn init(
    alloc: std.mem.Allocator,
    io: std.Io,
    initial: bool,
    home: []const u8,
) !?std.Io.Future(StartupCommandsError!void) {
    const con = try Connection.init();
    defer con.deinit();

    // Normal-Mode keyboard mappings
    inline for (.{
        // control maps
        cgopts.control_keys.quit ++ .{"exit"},
        cgopts.control_keys.float ++ .{"toggle-float"},
        cgopts.control_keys.fullscreen ++ .{"toggle-fullscreen"},
        cgopts.control_keys.close_window ++ .{"close"},

        // "irregular" focus & move maps
        // (that is, they don't exist for all 4 directions)
        .{ "Super", "J", "focus-view", "next" },
        .{ "Super", "K", "focus-view", "previous" },
        .{ "Super+Shift", "J", "swap", "next" },
        .{ "Super+Shift", "K", "swap", "previous" },
        .{ "Super", "Period", "focus-output", "next" },
        .{ "Super", "Comma", "focus-output", "previous" },
        .{ "Super+Shift", "Period", "send-to-output", "next" },
        .{ "Super+Shift", "Comma", "send-to-output", "previous" },
        .{ "Super+Shift", "Return", "zoom" },
        .{ "Super", "H", "send-layout-cmd", "rivertile", "main-ratio -0.05" },
        .{ "Super", "L", "send-layout-cmd", "rivertile", "main-ratio +0.05" },
        .{ "Super+Shift", "H", "send-layout-cmd", "rivertile", "main-count -1" },
        .{ "Super+Shift", "L", "send-layout-cmd", "rivertile", "main-count +1" },
    }) |map_cmd| {
        try con.runCommand(&(.{ "map", "normal" } ++ map_cmd));
    }

    // Confgen'd keymaps
    inline for (cgopts.launch_keys) |mapping| {
        const cmd = &.{ "map", "normal", mapping.@"0", mapping.@"1", "spawn", mapping.@"2" };
        try con.runCommand(cmd);
    }

    inline for (.{
        .{ .H, "left" },
        .{ .J, "down" },
        .{ .K, "up" },
        .{ .L, "right" },
    }) |kd| {
        const key = kd.@"0";
        const dir = kd.@"1";

        // moving floating views
        try con.runCommand(&.{ "map", "normal", "Super+Alt", @tagName(key), "move", dir, "100" });

        // snapping floating views
        try con.runCommand(&.{ "map", "normal", "Super+Alt+Control", @tagName(key), "snap", dir });

        // resizing floating views
        try con.runCommand(&.{ "map", "normal", "Super+Alt+Shift", @tagName(key), switch (key) {
            .H, .L => "horizontal",
            .J, .K => "vertical",
            else => unreachable,
        }, switch (key) {
            .J, .L => "100",
            .H, .K => "-100",
            else => unreachable,
        } });
    }

    // change layout orientation with arrow keys
    inline for (.{
        .{ "Up", "top" },
        .{ "Right", "right" },
        .{ "Down", "bottom" },
        .{ "Left", "left" },
    }) |kv| {
        try con.runCommand(&.{
            "map",
            "normal",
            "Super",
            kv.@"0",
            "send-layout-cmd",
            "rivertile",
            std.fmt.comptimePrint("main-location {s}", .{kv.@"1"}),
        });
    }

    // moving & resizing with the mouse
    try con.runCommand(&.{ "map-pointer", "normal", "Super", "BTN_LEFT", "move-view" });
    try con.runCommand(&.{ "map-pointer", "normal", "Super", "BTN_RIGHT", "resize-view" });

    // touchpad config
    inline for (.{
        .{ "click-method", "clickfinger" },
        .{ "tap-button-map", "left-right-middle" },
        .{ "tap", "enabled" },
    }) |cmd| {
        try con.runCommand(&[_][:0]const u8{ "input", "*" } ++ cmd);
    }

    // scratchpad
    {
        var pbuf: [64]u8 = undefined;
        const scratchpad_tag: u32 = 1 << 9;
        try con.runCommand(&.{ "spawn-tagmask", try std.fmt.bufPrintZ(&pbuf, "{}", .{~scratchpad_tag}) });

        const tag_s = try std.fmt.bufPrintZ(&pbuf, "{}", .{scratchpad_tag});
        try con.runCommand(&.{ "map", "normal", "Super", "P", "toggle-focused-tags", tag_s });
        try con.runCommand(&.{ "map", "normal", "Super+Shift", "P", "set-view-tags", tag_s });
    }

    // tag config
    for (0..9) |i| {
        var key_buf: [16]u8 = undefined;
        var tags_buf: [16]u8 = undefined;
        const key = try std.fmt.bufPrintZ(&key_buf, "{}", .{i + 1});
        const tags = try std.fmt.bufPrintZ(&tags_buf, "{}", .{@as(u32, 1) << @intCast(i)});

        try con.runCommand(&.{ "map", "normal", "Super", key, "set-focused-tags", tags });
        try con.runCommand(&.{ "map", "normal", "Super+Shift", key, "set-view-tags", tags });
        try con.runCommand(&.{ "map", "normal", "Super+Control", key, "toggle-focused-tags", tags });
        try con.runCommand(&.{ "map", "normal", "Super+Shift+Control", key, "toggle-view-tags", tags });
    }

    // "0" acts as "all tags", excluding special tags (beyond 9)
    const all_tags_s = std.fmt.comptimePrint("{}", .{0b111111111});
    try con.runCommand(&.{ "map", "normal", "Super", "0", "set-focused-tags", all_tags_s });
    try con.runCommand(&.{ "map", "normal", "Super+Shift", "0", "set-view-tags", all_tags_s });

    // passthrough mode
    const passthr_mode = "passthrough";
    try con.runCommand(&.{ "declare-mode", passthr_mode });
    try con.runCommand(&.{ "map", "normal", "Super", "F12", "enter-mode", passthr_mode });
    try con.runCommand(&.{ "map", passthr_mode, "Super", "F12", "enter-mode", "normal" });

    try con.runCommand(&.{ "set-repeat", "50", "300" });

    try con.runCommand(&.{ "background-color", "0x" ++ opt.catppuccin.base });
    try con.runCommand(&.{ "border-color-focused", "0x" ++ opt.catppuccin.red });
    try con.runCommand(&.{ "border-color-unfocused", "0x" ++ opt.catppuccin.sky });

    // Cursor config
    try con.runCommand(&.{ "set-cursor-warp", "on-focus-change" });
    try con.runCommand(&.{ "hide-cursor", "when-typing", "enabled" });

    try con.runCommand(&.{
        "xcursor-theme",
        opt.cursor.theme,
        std.fmt.comptimePrint("{}", .{opt.cursor.size}),
    });

    try con.runCommand(&.{ "rule-add", "-app-id", "vinput-editor", "float" });

    // disable client-side decoration (completely stupid concept)
    try con.runCommand(&.{ "rule-add", "-app-id", "*", "ssd" });

    try con.runCommand(&.{ "default-layout", "rivertile" });

    const init_path = try std.fs.path.join(
        alloc,
        &.{ home, ".config", "mzte_localconf", "river_init" },
    );
    defer alloc.free(init_path);

    log.info("Running river_init", .{});
    if (std.process.spawn(io, .{
        .argv = &.{ init_path, if (initial) "init" else "reinit" },
    })) |init_child_const| {
        var init_child = init_child_const;
        const term = try init_child.wait(io);
        if (!std.meta.eql(term, .{ .exited = 0 })) {
            log.err("river_init borked: {any}", .{term});
            return error.InitBorked;
        }
    } else |e| switch (e) {
        error.FileNotFound => log.info("no river_init", .{}),
        else => return e,
    }

    log.info("configuration finished, initial: {}", .{initial});

    // tell confgenfs we're now using river-classic
    confgenfs: {
        const cgfs_eval_path = try std.fs.path.join(
            alloc,
            &.{ home, "confgenfs", "_cgfs", "eval" },
        );
        defer alloc.free(cgfs_eval_path);

        const evalf = std.Io.Dir.cwd().openFile(io, cgfs_eval_path, .{ .mode = .write_only }) catch {
            log.warn("unable to open confgenfs eval file", .{});
            break :confgenfs;
        };
        defer evalf.close(io);

        var writer = evalf.writerStreaming(io, &.{});
        try writer.interface.writeAll(
            \\cg.opt.setCurrentWaylandCompositor "river-classic"
        );
    }

    if (initial) {
        log.info("spawning processes", .{});

        var child_arena = std.heap.ArenaAllocator.init(alloc);
        defer child_arena.deinit();

        // spawn initialization processes
        var child_group: std.Io.Group = .init;
        defer child_group.cancel(io);

        for ([_][]const []const u8{
            &.{
                "dbus-update-activation-environment",
                "DISPLAY",
                "XAUTHORITY",
                "WAYLAND_DISPLAY",
                "XDG_CURRENT_DESKTOP",
            },
            &.{
                "systemctl",
                "--user",
                "import-environment",
                "DISPLAY",
                "XAUTHORITY",
                "WAYLAND_DISPLAY",
                "XDG_CURRENT_DESKTOP",
            },
        }) |argv| {
            const runChild = struct {
                fn runChild(io_: std.Io, argv_: []const []const u8) !void {
                    var child = std.process.spawn(io_, .{ .argv = argv_ }) catch |e| switch (e) {
                        error.Canceled => return error.Canceled,
                        else => {
                            std.log.warn(
                                "couldn't spawn init process {f}: {}",
                                .{ common.fmt.command(argv_), e },
                            );
                            return;
                        },
                    };
                    _ = child.wait(io_) catch |e| switch (e) {
                        error.Canceled => return error.Canceled,
                        else => {
                            std.log.warn(
                                "couldn't wait for init process {f}: {}",
                                .{ common.fmt.command(argv_), e },
                            );
                            return;
                        },
                    };
                }
            }.runChild;
            child_group.async(io, runChild, .{ io, argv });
        }

        const future = try io.concurrent(spawnStartupCommands, .{ alloc, io });
        try child_group.await(io);
        return future;
    }

    return null;
}

pub const StartupCommandsError = std.mem.Allocator.Error || std.process.SpawnError ||
    std.process.Child.WaitError;

fn spawnStartupCommands(alloc: std.mem.Allocator, io: std.Io) StartupCommandsError!void {
    var children: std.ArrayList(std.process.Child) = try .initCapacity(
        alloc,
        cgopts.startup_commands.len,
    );
    defer {
        for (children.items) |*child| {
            child.kill(io);
        }
        children.deinit(alloc);
    }

    inline for (cgopts.startup_commands) |argv| {
        const child = try std.process.spawn(io, .{ .argv = initCommand(&argv) });
        children.appendAssumeCapacity(child);
    }

    for (children.items) |*child| {
        _ = try child.wait(io);
    }
}
