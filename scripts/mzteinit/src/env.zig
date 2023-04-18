const std = @import("std");
const DelimitedBuilder = @import("DelimitedBuilder.zig");

pub fn populateEnvironment(env: *std.process.EnvMap) !void {
    if (env.get("MZTE_ENV_SET")) |_| {
        return;
    }

    const alloc = env.hash_map.allocator;
    const home = if (env.get("HOME")) |home| try alloc.dupe(u8, home) else blk: {
        std.log.warn("Home not set, defaulting to current directory", .{});
        break :blk try std.fs.realpathAlloc(alloc, ".");
    };
    defer alloc.free(home);

    try env.put("MZTE_ENV_SET", "1");

    // set shell to fish to prevent anything from defaulting to mzteinit
    try env.put("SHELL", "/usr/bin/fish");

    // mix (elixir package manager) should respect XDG
    try env.put("MIX_XDG", "1");

    // use clang
    try env.put("CC", "clang");
    try env.put("CXX", "clang++");

    // neovim
    try env.put("EDITOR", "nvim");

    // PATH
    {
        var b = DelimitedBuilder.init(alloc, ':');
        errdefer b.deinit();

        var buf: [512]u8 = undefined;

        const fixed_home = [_][]const u8{
            ".mix/escripts",
            ".cargo/bin",
            ".local/bin",
            "go/bin",
            ".roswell/bin",
        };
        for (fixed_home) |fixed| {
            try b.push(try std.fmt.bufPrint(&buf, "{s}/{s}", .{ home, fixed }));
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
        }

        if (env.get("PATH")) |system_path| {
            try b.push(system_path);
        }

        try env.putMove(try alloc.dupe(u8, "PATH"), try b.toOwned());
    }

    // LUA_CPATH
    {
        var b = DelimitedBuilder.init(alloc, ';');
        errdefer b.deinit();

        var buf: [512]u8 = undefined;

        const fixed_home = [_][]const u8{
            ".local/lib/lua/?.so",
            ".local/lib/lua/?.lua",
        };
        for (fixed_home) |fixed| {
            try b.push(try std.fmt.bufPrint(&buf, "{s}/{s}", .{ home, fixed }));
        }
        try b.pushDirect(";;");

        try env.putMove(try alloc.dupe(u8, "LUA_CPATH"), try b.toOwned());
    }
}
