const std = @import("std");
const ffi = @import("ffi.zig");
const c = ffi.c;

const log = std.log.scoped(.compiler);

pub const std_options = struct {
    pub const log_level = .debug;
};

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
                    if (std.mem.endsWith(u8, entry.path, ".lua") or
                        std.mem.endsWith(u8, entry.path, ".fnl"))
                    {
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
        var outname = try alloc.dupe(u8, luafile);
        defer alloc.free(outname);

        c.lua_getfield(l, -1, "dump");

        if (std.mem.endsWith(u8, luafile, ".fnl")) {
            // this check is to prevent fennel code in aniseed plugins being unecessarily compiled.
            if (std.mem.containsAtLeast(u8, luafile, 1, "/fnl/") or
                // TODO: wonk
                std.mem.endsWith(u8, luafile, "macros.fnl"))
            {
                c.lua_pop(l, 1);
                continue;
            }

            // replace file extension
            std.mem.copy(u8, outname[outname.len - 3 ..], "lua");

            const res = try std.ChildProcess.exec(.{
                .allocator = alloc,
                .argv = &.{ "fennel", "-c", luafile },
            });

            defer alloc.free(res.stdout);
            defer alloc.free(res.stderr);

            if (!std.meta.eql(res.term, .{ .Exited = 0 })) {
                log.warn("error compiling fennel object {s}: {s}", .{ luafile, res.stderr });
                c.lua_pop(l, 1);
                continue;
            }

            const luafile_z = try alloc.dupeZ(u8, luafile);
            defer alloc.free(luafile_z);

            if (c.luaL_loadbuffer(l, res.stdout.ptr, res.stdout.len, luafile_z) != 0) {
                log.warn(
                    "error compiling fennel lua object {s}: {s}",
                    .{ luafile, ffi.luaToString(l, -1) },
                );
                c.lua_pop(l, 2);
                continue;
            }
        } else {
            const luafile_z = try alloc.dupeZ(u8, luafile);
            defer alloc.free(luafile_z);

            if (c.luaL_loadfile(l, luafile_z) != 0) {
                log.warn(
                    "error compiling lua object {s}: {s}",
                    .{ luafile, ffi.luaToString(l, -1) },
                );
                c.lua_pop(l, 2);
                continue;
            }
        }

        c.lua_pushboolean(l, 1); // strip debug info
        c.lua_call(l, 2, 1);

        var outlen: usize = 0;
        const outptr = c.lua_tolstring(l, -1, &outlen);

        var outfile = try std.fs.cwd().createFile(outname, .{});
        defer outfile.close();
        try outfile.writeAll(outptr[0..outlen]);

        c.lua_remove(l, -1);
    }
    log.info("compiled {} lua objects @ {s}", .{ files.items.len, path });
}
