const std = @import("std");
const ffi = @import("ffi.zig");
const c = ffi.c;
const ser = @import("ser.zig");

const log = std.log.scoped(.compiler);

pub const std_options = std.Options{
    .log_level = .debug,
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
    c.luaL_openlibs(l);

    // add fennel lib to lua path
    // fennel is made to run on lua 5.4, but ends up working with LJ too
    c.lua_getfield(l, c.LUA_GLOBALSINDEX, "package");
    c.lua_getfield(l, -1, "path");
    ffi.luaPushString(l, ";" ++ "/usr/share/lua/5.4/fennel.lua");
    c.lua_concat(l, 2);
    c.lua_setfield(l, -2, "path");
    c.lua_pop(l, 1);

    // set optimization level
    c.lua_getfield(l, c.LUA_REGISTRYINDEX, "_LOADED");
    c.lua_getfield(l, -1, "jit.opt");
    c.lua_remove(l, -2);
    c.lua_getfield(l, -1, "start");
    c.lua_remove(l, -2);
    c.lua_pushinteger(l, 9);
    c.lua_call(l, 1, 0);

    // prepare state
    // load fennel
    log.info("Loading fennel compiler", .{});
    c.lua_getfield(l, c.LUA_GLOBALSINDEX, "require");
    ffi.luaPushString(l, "fennel");
    if (c.lua_pcall(l, 1, 1, 0) != 0) {
        log.err("Failed to load fennel compiler: {s}", .{ffi.luaToString(l, -1)});
        return error.FennelLoad;
    }
    c.lua_getfield(l, c.LUA_GLOBALSINDEX, "string");

    // an arena allocator to hold data to be used during the build
    var build_arena = std.heap.ArenaAllocator.init(alloc);
    defer build_arena.deinit();
    const build_alloc = build_arena.allocator();

    // a list of lua files to compile
    var files = std.ArrayList([]const u8).init(alloc);
    defer files.deinit();

    if ((try std.fs.cwd().statFile(path)).kind == .directory) {
        var dir = try std.fs.cwd().openDir(path, .{ .iterate = true });
        defer dir.close();

        var walker = try dir.walk(alloc);
        defer walker.deinit();

        while (try walker.next()) |entry| {
            const entry_path = try std.fs.path.join(build_alloc, &.{ path, entry.path });

            switch (entry.kind) {
                .file => {
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

    var n_fnl: usize = 0;
    var n_lua: usize = 0;

    const stacktop = c.lua_gettop(l);

    for (files.items) |luafile| {
        // reset lua stack
        defer c.lua_settop(l, stacktop);

        var outname = try alloc.dupe(u8, luafile);
        defer alloc.free(outname);

        c.lua_getfield(l, -1, "dump");

        const is_fennel = std.mem.endsWith(u8, luafile, ".fnl");

        if (is_fennel) {
            // this check is to prevent fennel code in aniseed plugins being unecessarily compiled.
            if (std.mem.containsAtLeast(u8, luafile, 1, "/fnl/") or
                // TODO: wonk
                std.mem.endsWith(u8, luafile, "macros.fnl"))
            {
                continue;
            }

            // replace file extension
            @memcpy(outname[outname.len - 3 ..], "lua");

            var file = try std.fs.cwd().openFile(luafile, .{});
            defer file.close();
            // 16 MB better be enough
            const data = try file.readToEndAlloc(build_alloc, 1024 * 1024 * 16);

            // fennel.compile-string
            c.lua_getfield(l, -3, "compile-string");
            ffi.luaPushString(l, data);
            // push fennel compile options
            ser.luaPushAny(l.?, .{
                .filename = luafile,
                // no need for indenting, this code will likely not be seen by anyone
                .indent = "",
            });
            if (c.lua_pcall(l, 2, 1, 0) != 0) {
                log.warn(
                    "error compiling fennel object {s}: {s}",
                    .{ luafile, ffi.luaToString(l, -1) },
                );
                continue;
            }

            const compiled = ffi.luaToString(l, -1);
            const luafile_z = try build_alloc.dupeZ(u8, luafile);

            if (c.luaL_loadbuffer(l, compiled.ptr, compiled.len, luafile_z) != 0) {
                log.warn(
                    "error compiling fennel lua object {s}: {s}",
                    .{ luafile, ffi.luaToString(l, -1) },
                );
                continue;
            }

            // remove compiled lua code string
            c.lua_remove(l, -2);
        } else {
            const luafile_z = try alloc.dupeZ(u8, luafile);
            defer alloc.free(luafile_z);

            if (c.luaL_loadfile(l, luafile_z) != 0) {
                log.warn(
                    "error compiling lua object {s}: {s}",
                    .{ luafile, ffi.luaToString(l, -1) },
                );
                continue;
            }
        }

        c.lua_pushboolean(l, 1); // strip debug info
        c.lua_call(l, 2, 1);

        const outdata = ffi.luaToString(l, -1);

        var outfile = try std.fs.cwd().createFile(outname, .{});
        defer outfile.close();
        try outfile.writeAll(outdata);

        if (is_fennel) {
            n_fnl += 1;
        } else {
            n_lua += 1;
        }
    }
    log.info("compiled {} lua and {} fennel objects @ {s}", .{ n_lua, n_fnl, path });
}
