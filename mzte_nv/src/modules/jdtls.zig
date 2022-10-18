/// Module for the JDTLS java language server, including utilities
/// for setting up nvim-jdtls
const std = @import("std");
const ffi = @import("../ffi.zig");
const c = ffi.c;

pub fn pushModtable(l: *c.lua_State) void {
    c.lua_newtable(l);
    c.lua_pushcfunction(l, ffi.luaFunc(lFindRuntimes));
    c.lua_setfield(l, -2, "findRuntimes");
}

const Runtime = struct {
    version: []const u8,
    name: []const u8,
};
const runtime_map = [_]Runtime{
    .{ .version = "18", .name = "JavaSE-18" },
    .{ .version = "17", .name = "JavaSE-17" },
    .{ .version = "16", .name = "JavaSE-16" },
    .{ .version = "15", .name = "JavaSE-15" },
    .{ .version = "14", .name = "JavaSE-14" },
    .{ .version = "13", .name = "JavaSE-13" },
    .{ .version = "12", .name = "JavaSE-12" },
    .{ .version = "11", .name = "JavaSE-11" },
    .{ .version = "10", .name = "JavaSE-10" },
    .{ .version = "9", .name = "JavaSE-9" },
    .{ .version = "8", .name = "JavaSE-1.8" },
    .{ .version = "7", .name = "JavaSE-1.7" },
    .{ .version = "6", .name = "JavaSE-1.6" },
    .{ .version = "5", .name = "J2SE-1.5" }, // probably redundant, but JDTLS supports it
};

fn lFindRuntimes(l: *c.lua_State) !c_int {
    var jvmdir = try std.fs.openIterableDirAbsolute("/usr/lib/jvm/", .{});
    defer jvmdir.close();

    c.lua_newtable(l);

    var buf: [512]u8 = undefined;
    var idx: c_int = 1;
    var iter = jvmdir.iterate();
    while (try iter.next()) |jvm| {
        if (jvm.kind != .Directory or !std.mem.startsWith(u8, jvm.name, "java-"))
            continue;

        for (runtime_map) |rt| {
            if (!std.mem.containsAtLeast(u8, jvm.name, 1, rt.version))
                continue;

            // push a table with a name field (must be a name from runtime_map)
            // and a path field (path to the runtime's home)
            c.lua_newtable(l);

            c.lua_pushstring(l, rt.name.ptr);
            c.lua_setfield(l, -2, "name");

            const path = try std.fmt.bufPrintZ(&buf, "/usr/lib/jvm/{s}/", .{jvm.name});
            c.lua_pushstring(l, path.ptr);
            c.lua_setfield(l, -2, "path");

            // append table to list
            c.lua_rawseti(l, -2, idx);
            idx += 1;

            break;
        }
    }

    return 1;
}
