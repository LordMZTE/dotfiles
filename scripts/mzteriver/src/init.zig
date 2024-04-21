const std = @import("std");
const opts = @import("opts");

const log = std.log.scoped(.init);

const Connection = @import("Connection.zig");

fn keybindCommand(comptime base: []const u8) [:0]const u8 {
    return "systemd-cat --level-prefix=false -- " ++ base;
}

fn initCommand(comptime argv: []const [:0]const u8) []const [:0]const u8 {
    return &[_][:0]const u8{
        "systemd-cat",
        "--level-prefix=false",
        "--identifier=" ++ argv[0],
        "--",
    } ++ argv;
}

pub fn init(alloc: std.mem.Allocator, initial: bool) !void {
    const con = try Connection.init();
    defer con.deinit();

    // Normal-Mode keyboard mappings
    inline for (.{
        // "run command" maps
        .{ "Super", "Return", "spawn", keybindCommand(opts.term_command) },
        .{ "Super+Control", "E", "spawn", keybindCommand(opts.file_manager_command) },
        .{ "Super+Control", "B", "spawn", keybindCommand(opts.browser_command) },
        .{ "Super+Control", "V", "spawn", keybindCommand("vinput md") },
        .{ "Super+Control", "L", "spawn", keybindCommand("physlock") },
        .{ "Super+Shift", "P", "spawn", keybindCommand("gpower2") },
        .{ "Alt", "Space", "spawn", keybindCommand("rofi -show combi") },
        .{ "Super+Alt", "Space", "spawn", keybindCommand("rofi -show emoji") },
        .{ "None", "Print", "spawn", keybindCommand("grim -g \"$(slurp; sleep 1)\" ~/Downloads/screenshot.png") },
        .{ "Shift", "Print", "spawn", keybindCommand("grim -g \"$(slurp; sleep 1)\" - | feh -") },

        // media keys
        .{ "None", "XF86Eject", "spawn", keybindCommand("eject -T") },
        .{ "None", "XF86AudioRaiseVolume", "spawn", keybindCommand("pactl set-sink-volume @DEFAULT_SINK@ +5%") },
        .{ "None", "XF86AudioLowerVolume", "spawn", keybindCommand("pactl set-sink-volume @DEFAULT_SINK@ -5%") },
        .{ "None", "XF86AudioMute", "spawn", keybindCommand("pactl set-sink-mute @DEFAULT_SINK@ toggle") },
        .{ "None", "XF86AudioMicMute", "spawn", keybindCommand("pactl set-source-mute @DEFAULT_SINK@ toggle") },
        .{ "None", "XF86AudioMedia", "spawn", keybindCommand("playerctl play-pause") },
        .{ "None", "XF86AudioPlay", "spawn", keybindCommand("playerctl play-pause") },
        .{ "None", "XF86AudioPrev", "spawn", keybindCommand("playerctl previous") },
        .{ "None", "XF86AudioNext", "spawn", keybindCommand("playerctl next") },

        // control maps
        .{ "Super+Shift", "E", "exit" },
        .{ "Super", "Space", "toggle-float" },
        .{ "Super", "F", "toggle-fullscreen" },
        .{ "Super+Shift", "Q", "close" },

        // screenshot

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

    // "0" acts as "all tags"
    const all_tags_s = std.fmt.comptimePrint("{}", .{std.math.maxInt(u32)});
    try con.runCommand(&.{ "map", "normal", "Super", "0", "set-focused-tags", all_tags_s });
    try con.runCommand(&.{ "map", "normal", "Super+Shift", "0", "set-view-tags", all_tags_s });

    // passthrough mode
    const passthr_mode = "passthrough";
    try con.runCommand(&.{ "declare-mode", passthr_mode });
    try con.runCommand(&.{ "map", "normal", "Super", "F12", "enter-mode", passthr_mode });
    try con.runCommand(&.{ "map", passthr_mode, "Super", "F12", "enter-mode", "normal" });

    try con.runCommand(&.{ "set-repeat", "50", "300" });

    try con.runCommand(&.{ "border-color-focused", "0x" ++ opts.catppuccin_red });
    try con.runCommand(&.{ "border-color-unfocused", "0x" ++ opts.catppuccin_sky });

    try con.runCommand(&.{ "hide-cursor", "when-typing", "enabled" });

    try con.runCommand(&.{
        "xcursor-theme",
        opts.cursor_theme,
        std.fmt.comptimePrint("{}", .{opts.cursor_size}),
    });

    try con.runCommand(&.{ "rule-add", "-app-id", "vinput-editor", "float" });

    // disable client-side decoration (completely stupid concept)
    try con.runCommand(&.{ "rule-add", "-app-id", "*", "ssd" });

    try con.runCommand(&.{ "default-layout", "rivertile" });

    const home = std.posix.getenv("HOME") orelse return error.HomeNotSet;
    const init_path = try std.fs.path.join(
        alloc,
        &.{ home, ".config", "mzte_localconf", "river_init" },
    );
    defer alloc.free(init_path);

    var init_child = std.process.Child.init(
        &.{ init_path, if (initial) "init" else "reinit" },
        alloc,
    );
    const term = init_child.spawnAndWait() catch |e| switch (e) {
        error.FileNotFound => b: {
            log.info("no river_init", .{});
            break :b std.process.Child.Term{ .Exited = 0 };
        },
        else => return e,
    };

    if (!std.meta.eql(term, .{ .Exited = 0 })) {
        log.err("river_init borked: {}", .{term});
        return error.InitBorked;
    }

    log.info("configuration finished, initial: {}", .{initial});

    // tell confgenfs we're now using river
    confgenfs: {
        const cgfs_eval_path = try std.fs.path.join(
            alloc,
            &.{ home, "confgenfs", "_cgfs", "eval" },
        );
        defer alloc.free(cgfs_eval_path);

        const evalf = std.fs.cwd().openFile(cgfs_eval_path, .{ .mode = .write_only }) catch {
            log.warn("unable to open confgenfs eval file", .{});
            break :confgenfs;
        };
        defer evalf.close();

        try evalf.writeAll(
            \\cg.opt.setCurrentWaylandCompositor "river"
        );
    }

    if (initial) {
        log.info("spawning processes", .{});

        var child_arena = std.heap.ArenaAllocator.init(alloc);
        defer child_arena.deinit();

        // spawn background processes
        inline for (.{
            .{"wlbg"},
            .{"waybar"},
            .{ "dbus-update-activation-environment", "DISPLAY", "XAUTHORITY", "WAYLAND_DISPLAY", "XDG_CURRENT_DESKTOP" },
            .{ "systemctl", "--user", "import-environment", "DISPLAY", "XAUTHORITY", "WAYLAND_DISPLAY", "XDG_CURRENT_DESKTOP" },
            .{ "rivertile", "-view-padding", "6", "-outer-padding", "6" },
        }) |argv| {
            // TODO: wonk
            // We use an arena here to prevent leaks because process.Child apparently doesn't support
            // detaching.
            var child = std.process.Child.init(initCommand(&argv), child_arena.allocator());
            try child.spawn();
        }
    }
}
