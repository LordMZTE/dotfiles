const std = @import("std");
const sysdaemon = @import("sysdaemon.zig");

const log = std.log.scoped(.env);

const delimitedWriter = @import("delimited_writer.zig").delimitedWriter;

/// Initialize the environment.
/// Returns true if the environment should be transferred to the system daemon.
pub fn populateEnvironment(env: *std.process.EnvMap) !bool {
    // buffer for building values for env vars
    var buf: [1024 * 8]u8 = undefined;

    // buffer for small one-off operations while `buf` is in use
    var sbuf: [512]u8 = undefined;

    if (env.get("MZTE_ENV_SET")) |_| {
        return false;
    }

    const alloc = env.hash_map.allocator;
    const home = if (env.get("HOME")) |home| try alloc.dupe(u8, home) else blk: {
        log.warn("Home not set, defaulting to current directory", .{});
        break :blk try std.fs.realpathAlloc(alloc, ".");
    };
    defer alloc.free(home);

    try env.put("MZTE_ENV_SET", "1");

    // XDG vars
    inline for (.{
        .{ "XDG_DATA_HOME", ".local/share" },
        .{ "XDG_CONFIG_HOME", ".config" },
        .{ "XDG_STATE_HOME", ".local/state" },
        .{ "XDG_CACHE_HOME", ".local/cache" },
    }) |kv| {
        try env.put(kv.@"0", try std.fmt.bufPrint(&sbuf, "{s}/{s}", .{ home, kv.@"1" }));
    }

    // set shell to fish to prevent anything from defaulting to mzteinit
    try env.put("SHELL", "/usr/bin/fish");

    // mix (elixir package manager) should respect XDG
    try env.put("MIX_XDG", "1");

    // use clang
    try env.put("CC", "clang");
    try env.put("CXX", "clang++");

    // neovim
    try env.put("EDITOR", "nvim");

    // Java options
    {
        var bufstream = std.io.fixedBufferStream(&buf);
        var b = delimitedWriter(bufstream.writer(), ' ');

        // anti-alias text
        try b.push("-Dawt.useSystemAAFontSettings=on");
        try b.push("-Dswing.aatext=true");

        // GTK theme
        try b.push("-Dswing.defaultlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel");
        try b.push("-Dswing.crossplatformlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel");

        try env.put("_JAVA_OPTIONS", bufstream.getWritten());
    }

    // GUI options
    {
        try env.put("QT_QPA_PLATFORMTHEME", "gtk2");
        try env.put("GTK_THEME", "Catppuccin-Mocha-Standard-Pink-Dark");

        // icon path
        icons: {
            const path = "/usr/share/icons/candy-icons";
            var dir = std.fs.openIterableDirAbsolute(path, .{}) catch {
                log.warn(
                    "Couldn't open candy-icons directory @ `{s}`, not setting ICONPATH",
                    .{path},
                );
                break :icons;
            };
            defer dir.close();

            var bufstream = std.io.fixedBufferStream(&buf);
            var b = delimitedWriter(bufstream.writer(), ':');

            var iter = dir.iterate();
            while (try iter.next()) |entry| {
                if (entry.kind != .directory)
                    continue;

                const dpath = try std.fs.path.join(alloc, &.{ path, entry.name });
                defer alloc.free(dpath);

                try b.push(dpath);
            }

            try env.put("ICONPATH", bufstream.getWritten());
        }
    }

    // Rofi path
    try env.put(
        "ROFI_PLUGIN_PATH",
        try std.fmt.bufPrint(&sbuf, "/usr/lib/rofi:{s}/.local/lib/rofi", .{home}),
    );

    // PATH
    {
        var bufstream = std.io.fixedBufferStream(&buf);
        var b = delimitedWriter(bufstream.writer(), ':');

        const fixed_home = [_][]const u8{
            ".mix/escripts",
            ".cargo/bin",
            ".local/bin",
            "go/bin",
            ".roswell/bin",
        };
        for (fixed_home) |fixed| {
            try b.push(try std.fmt.bufPrint(&sbuf, "{s}/{s}", .{ home, fixed }));
        }

        // racket bins
        racket: {
            const res = std.ChildProcess.exec(.{
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

        try env.put("PATH", bufstream.getWritten());
    }

    // LUA_CPATH
    {
        var bufstream = std.io.fixedBufferStream(&buf);
        var b = delimitedWriter(bufstream.writer(), ';');

        const fixed_home = [_][]const u8{
            ".local/lib/lua/?.so",
            ".local/lib/lua/?.lua",
        };
        for (fixed_home) |fixed| {
            try b.push(try std.fmt.bufPrint(&sbuf, "{s}/{s}", .{ home, fixed }));
        }
        try b.writer.writeAll(";;");

        try env.put("LUA_CPATH", bufstream.getWritten());
    }

    return true;
}

pub fn populateSysdaemonEnvironment(env: *const std.process.EnvMap) !void {
    if (try sysdaemon.getCurrentSystemDaemon() != .systemd)
        return;

    var argv = try std.ArrayList([]const u8).initCapacity(env.hash_map.allocator, env.count() + 3);
    defer argv.deinit();

    var arg_arena = std.heap.ArenaAllocator.init(env.hash_map.allocator);
    defer arg_arena.deinit();

    try argv.appendSlice(&.{ "systemctl", "--user", "set-environment" });

    var env_iter = env.iterator();
    while (env_iter.next()) |entry| {
        try argv.append(try std.fmt.allocPrint(
            arg_arena.allocator(),
            "{s}={s}",
            .{ entry.key_ptr.*, entry.value_ptr.* },
        ));
    }

    log.debug("sysdaemon env cmd: {s}", .{argv.items});

    var child = std.ChildProcess.init(argv.items, env.hash_map.allocator);
    const term = try child.spawnAndWait();

    if (!std.meta.eql(term, .{ .Exited = 0 })) {
        log.warn("Failed setting system environment, process exited with {}", .{term});
    }
}
