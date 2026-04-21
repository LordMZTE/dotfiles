const std = @import("std");
const opts = @import("opts");

const ffi = @import("lualib");
const c = ffi.c;

const log = std.log.scoped(.compiler);

pub const std_options = std.Options{
    .log_level = .debug,
    .logFn = @import("common").logFn,
};

pub const fnl_env_var = "MZTE_NV_FENNEL";

pub fn main(init: std.process.Init) !void {
    var arg_iter = try init.minimal.args.iterateAllocator(init.gpa);
    defer arg_iter.deinit();

    var argv0: ?[]const u8 = null;
    const maybe_input_arg = arg: {
        argv0 = arg_iter.next() orelse break :arg null;
        const arg = arg_iter.next() orelse break :arg null;
        if (arg_iter.skip()) break :arg null; // too many args
        break :arg arg;
    };

    const input_arg = maybe_input_arg orelse {
        log.err(
            \\Usage: {?s} [dir]
            \\
            \\`dir` is a path to a normal lua neovim configuration
            \\(or any other path containing lua files.)
        ,
            .{argv0},
        );

        return error.InvalidArgs;
    };

    try doCompile(input_arg, init.io, init.gpa, init.environ_map.get(fnl_env_var));
}

pub fn doCompile(
    path: []const u8,
    io: std.Io,
    alloc: std.mem.Allocator,
    fnl_path: ?[]const u8,
) !void {
    const l = c.luaL_newstate();
    defer c.lua_close(l);

    // load lua libs
    c.luaL_openlibs(l);

    // add fennel lib to lua path
    // fennel is made to run on lua 5.4, but ends up working with LJ too
    c.lua_getfield(l, c.LUA_GLOBALSINDEX, "package");
    c.lua_getfield(l, -1, "path");
    ffi.luaPushString(l, ";");
    ffi.luaPushString(l, if (@hasField(@TypeOf(opts), "nix"))
        opts.nix.@"fennel.lua"
    else
        (fnl_path orelse "/usr/share/lua/5.4/fennel.lua"));
    c.lua_concat(l, 3);
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
    var files: std.ArrayListUnmanaged([]const u8) = .empty;
    defer files.deinit(alloc);

    if ((try std.Io.Dir.cwd().statFile(io, path, .{})).kind == .directory) {
        var dir = try std.Io.Dir.cwd().openDir(io, path, .{ .iterate = true });
        defer dir.close(io);

        var walker = try dir.walk(alloc);
        defer walker.deinit();

        while (try walker.next(io)) |entry| {
            const entry_path = try std.fs.path.join(build_alloc, &.{ path, entry.path });

            switch (entry.kind) {
                .file => {
                    if (std.mem.endsWith(u8, entry.path, ".lua") or
                        std.mem.endsWith(u8, entry.path, ".fnl"))
                    {
                        try files.append(alloc, entry_path);
                    }
                },
                else => {},
            }
        }
    } else {
        try files.append(alloc, path);
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

            var file = try std.Io.Dir.cwd().openFile(io, luafile, .{});
            defer file.close(io);

            var reader = file.reader(io, &.{});

            // 16 MB better be enough
            const data = try reader.interface.allocRemaining(
                build_alloc,
                .limited(1024 * 1024 * 16),
            );

            // fennel.compile-string
            c.lua_getfield(l, -3, "compile-string");
            ffi.luaPushString(l, data);
            // push fennel compile options
            ffi.ser.luaPushAny(l.?, .{
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

        var outfile = try std.Io.Dir.cwd().createFile(io, outname, .{});
        defer outfile.close(io);
        try outfile.writeStreamingAll(io, outdata);

        if (is_fennel) {
            n_fnl += 1;
        } else {
            n_lua += 1;
        }
    }
    log.info("compiled {} lua and {} fennel objects @ {s}", .{ n_lua, n_fnl, path });
}
