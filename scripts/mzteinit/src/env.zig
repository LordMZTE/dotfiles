const std = @import("std");
const common = @import("common");
const cg = @import("opts").cg;

const sysdaemon = @import("sysdaemon.zig");

const util = @import("util.zig");

const msg = @import("message.zig").msg;

const log = std.log.scoped(.env);

/// Initialize the environment.
/// Returns true if the environment should be transferred to the system daemon.
pub fn populateEnvironment(env: *std.process.EnvMap) !bool {
    try msg("loading environment...", .{});
    // buffer for building values for env vars
    var buf: [1024 * 8]u8 = undefined;

    // buffer for small one-off operations while `buf` is in use
    var sbuf: [512]u8 = undefined;

    if (env.get("MZTE_ENV_SET")) |_|
        return false;

    const alloc = env.hash_map.allocator;
    const home = if (env.get("HOME")) |home| try alloc.dupe(u8, home) else blk: {
        log.warn("Home not set, defaulting to current directory", .{});
        break :blk try std.fs.realpathAlloc(alloc, ".");
    };
    defer alloc.free(home);

    // PATH
    {
        var bufstream = std.Io.Writer.fixed(&buf);
        var b = common.DelimitedWriter{ .writer = &bufstream, .delimiter = ':' };

        for ([_][]const u8{
            ".nix-profile/bin",
            ".mix/escripts",
            ".cargo/bin",
            ".local/bin",
            "go/bin",
            ".roswell/bin",
        }) |fixed| {
            try b.push(try std.fmt.bufPrint(&sbuf, "{s}/{s}", .{ home, fixed }));
        }

        // racket bins
        racket: {
            try msg("acquiring racket binary path...", .{});
            const res = std.process.Child.run(.{
                .allocator = alloc,
                .argv = &.{
                    "racket",
                    "-l",
                    "racket/base",
                    "-e",
                    "(require setup/dirs) (display (path->string (find-user-console-bin-dir)))",
                },
            }) catch break :racket;
            defer alloc.free(res.stdout);
            defer alloc.free(res.stderr);

            try b.push(res.stdout);

            log.info("racket binary path registered", .{});
        }

        if (env.get("PATH")) |system_path| {
            try b.push(system_path);
        }

        try env.put("PATH", bufstream.buffered());
    }

    try env.put("MZTE_ENV_SET", "1");

    // XDG vars
    for ([_][2][]const u8{
        .{ "XDG_DATA_HOME", ".local/share" },
        .{ "XDG_CONFIG_HOME", ".config" },
        .{ "XDG_STATE_HOME", ".local/state" },
        .{ "XDG_CACHE_HOME", ".local/cache" },
    }) |kv| {
        try env.put(kv[0], try std.fmt.bufPrint(&sbuf, "{s}/{s}", .{ home, kv[1] }));
    }

    // XDG_DATA_DIRS
    {
        var bufstream = std.Io.Writer.fixed(&buf);
        var b = common.DelimitedWriter{ .writer = &bufstream, .delimiter = ':' };

        // Default value taken from archwiki.
        // https://wiki.archlinux.org/title/XDG_Base_Directory
        try b.push(env.get("XDG_DATA_DIRS") orelse "/usr/local/share:/usr/share");

        inline for (.{ ".nix-profile/share", ".local/share" }) |base| {
            const full = try std.fmt.bufPrint(&sbuf, "{s}/" ++ base, .{home});
            if (!std.mem.containsAtLeast(u8, bufstream.buffered(), 1, full)) {
                log.info("adding " ++ base ++ " to XDG_DATA_DIRS", .{});
                try b.push(full);
            }
        }

        try env.put("XDG_DATA_DIRS", bufstream.buffered());
    }

    // set shell to nu to prevent anything from defaulting to mzteinit
    if (try util.findInPath(
        alloc,
        env.get("PATH") orelse unreachable,
        "nu",
    )) |nu| {
        defer alloc.free(nu);
        try env.put("SHELL", nu);
    } else {
        log.warn("nu not found! setting $SHELL to /bin/sh", .{});
        try env.put("SHELL", "/bin/sh");
    }

    // mix (elixir package manager) should respect XDG
    try env.put("MIX_XDG", "1");

    // neovim
    try env.put("EDITOR", "nvim");

    try env.put("TERMINAL", cg.term.exec);

    // This is required for reasons unknown for `man` to show colors
    try env.put("GROFF_NO_SGR", "1");

    // Java options
    {
        var bufstream = std.Io.Writer.fixed(&buf);
        var b = common.DelimitedWriter{ .writer = &bufstream, .delimiter = ' ' };

        // anti-alias text
        try b.push("-Dawt.useSystemAAFontSettings=on");
        try b.push("-Dswing.aatext=true");

        // GTK theme
        try b.push("-Dswing.defaultlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel");
        try b.push("-Dswing.crossplatformlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel");

        try env.put("_JAVA_OPTIONS", bufstream.buffered());
    }

    // GUI options
    {
        try env.put("QT_QPA_PLATFORMTHEME", "qt5ct");
        try env.put("GTK_THEME", cg.gtk_theme); // gtk theme from confgen

        // this stops GTK from dbus-launching the mid-bogglingly pointless at-spi daemon
        try env.put("NO_AT_BRIDGE", "1");
        try env.put("GTK_A11Y", "none");

        // use xdg-desktop-portal
        try env.put("GTK_USE_PORTAL", "1");

        // icon path
        icons: {
            try msg("building $ICONPATH...", .{});
            const path = "/usr/share/icons/candy-icons";
            var dir = std.fs.openDirAbsolute(path, .{ .iterate = true }) catch {
                log.warn(
                    "Couldn't open candy-icons directory @ `{s}`, not setting ICONPATH",
                    .{path},
                );
                break :icons;
            };
            defer dir.close();

            var bufstream = std.Io.Writer.fixed(&buf);
            var b = common.DelimitedWriter{ .writer = &bufstream, .delimiter = ':' };

            var iter = dir.iterate();
            while (try iter.next()) |entry| {
                if (entry.kind != .directory)
                    continue;

                const dpath = try std.fs.path.join(alloc, &.{ path, entry.name });
                defer alloc.free(dpath);

                try b.push(dpath);
            }

            try env.put("ICONPATH", bufstream.buffered());
        }
    }

    // Rofi path
    try env.put(
        "ROFI_PLUGIN_PATH",
        try std.fmt.bufPrint(&sbuf, "/usr/lib/rofi:{s}/.local/lib/rofi", .{home}),
    );

    // LUA_CPATH
    {
        var bufstream = std.Io.Writer.fixed(&buf);
        var b = common.DelimitedWriter{ .writer = &bufstream, .delimiter = ';' };

        const fixed_home = [_][]const u8{
            ".local/lib/lua/?.so",
            ".local/lib/lua/?.lua",
        };
        for (fixed_home) |fixed| {
            try b.push(try std.fmt.bufPrint(&sbuf, "{s}/{s}", .{ home, fixed }));
        }
        try b.writer.writeAll(";;");

        try env.put("LUA_CPATH", bufstream.buffered());
    }

    return true;
}

pub fn populateSysdaemonEnvironment(env: *const std.process.EnvMap) !void {
    if (try sysdaemon.getCurrentSystemDaemon() != .systemd)
        return;

    try msg("updating SystemD environment...", .{});

    var argv = try std.ArrayListUnmanaged([]const u8).initCapacity(env.hash_map.allocator, env.count() + 3);
    defer argv.deinit(env.hash_map.allocator);

    var arg_arena = std.heap.ArenaAllocator.init(env.hash_map.allocator);
    defer arg_arena.deinit();

    try argv.appendSlice(env.hash_map.allocator, &.{ "systemctl", "--user", "set-environment" });

    var env_iter = env.iterator();
    while (env_iter.next()) |entry| {
        try argv.append(env.hash_map.allocator, try std.fmt.allocPrint(
            arg_arena.allocator(),
            "{s}={s}",
            .{ entry.key_ptr.*, entry.value_ptr.* },
        ));
    }

    log.debug("sysdaemon env cmd: {f}", .{common.fmt.command(argv.items)});

    var child = std.process.Child.init(argv.items, env.hash_map.allocator);
    const term = try child.spawnAndWait();

    if (!std.meta.eql(term, .{ .Exited = 0 })) {
        log.warn("Failed setting system environment, process exited with {}", .{term});
    }
}
