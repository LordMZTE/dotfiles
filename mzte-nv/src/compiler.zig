const std = @import("std");
const c = @import("ffi.zig").c;

const log = std.log.scoped(.compiler);

pub const log_level = .debug;

pub fn main() !void {
    if (std.os.argv.len != 2) {
        log.err(
            \\Usage: {s} [dir]
            \\
            \\`dir` is a path to a normal lua neovim configuration
            \\(or any other path containing lua files.)
        ,
            .{std.os.argv[0]},
        );

        return error.InvalidArgs;
    }

    const input_arg = std.mem.span(std.os.argv[1]);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    try doCompile(input_arg, gpa.allocator());
}

pub fn doCompile(path: []const u8, alloc: std.mem.Allocator) !void {
    const l = c.luaL_newstate();
    defer c.lua_close(l);

    // load lua libs
    _ = c.luaopen_string(l);
    _ = c.luaopen_jit(l);

    // set optimization level
    c.lua_getfield(l, c.LUA_REGISTRYINDEX, "_LOADED");
    c.lua_getfield(l, -1, "jit.opt");
    c.lua_remove(l, -2);
    c.lua_getfield(l, -1, "start");
    c.lua_remove(l, -2);
    c.lua_pushinteger(l, 9);
    c.lua_call(l, 1, 0);

    // prepare state
    c.lua_getfield(l, c.LUA_GLOBALSINDEX, "string");

    // an arena allocator to hold data to be used during the build
    var build_arena = std.heap.ArenaAllocator.init(alloc);
    defer build_arena.deinit();
    const build_alloc = build_arena.allocator();

    // a list of lua files to compile
    var files = std.ArrayList([]const u8).init(alloc);
    defer files.deinit();

    if ((try std.fs.cwd().statFile(path)).kind == .Directory) {
        var dir = try std.fs.cwd().openIterableDir(path, .{});
        defer dir.close();

        var walker = try dir.walk(alloc);
        defer walker.deinit();

        while (try walker.next()) |entry| {
            const entry_path = try std.fs.path.join(build_alloc, &.{ path, entry.path });

            switch (entry.kind) {
                .File => {
                    if (std.mem.endsWith(u8, entry.path, ".lua")) {
                        try files.append(entry_path);
                    }
                },
                else => {},
            }
        }
    } else {
        try files.append(path);
    }

    for (files.items) |luafile| {
        const luafile_z = try alloc.dupeZ(u8, luafile);
        defer alloc.free(luafile_z);

        c.lua_getfield(l, -1, "dump");
        if (c.luaL_loadfile(l, luafile_z) != 0) {
            log.warn(
                "error compiling lua object {s}: {s}",
                .{ luafile, c.lua_tolstring(l, -1, null) },
            );
            c.lua_pop(l, 2);
            continue;
        }

        c.lua_pushboolean(l, 1); // strip debug info
        c.lua_call(l, 2, 1);

        var outlen: usize = 0;
        const outptr = c.lua_tolstring(l, -1, &outlen);

        var outfile = try std.fs.cwd().createFile(luafile, .{});
        defer outfile.close();
        try outfile.writeAll(outptr[0..outlen]);

        c.lua_remove(l, -1);
    }
    log.info("compiled {} lua objects @ {s}", .{ files.items.len, path });
}
