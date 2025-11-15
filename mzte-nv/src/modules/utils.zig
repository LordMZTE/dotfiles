const std = @import("std");
const ffi = @import("lualib");
const c = ffi.c;

pub fn luaPush(l: *c.lua_State) void {
    ffi.ser.luaPushAny(l, .{
        .findInPath = ffi.luaFunc(lFindInPath),

        .map_opt = .{ .noremap = true, .silent = true },
    });
}

/// This is basically a reimplementation of `which`.
fn lFindInPath(l: *c.lua_State) !c_int {
    const bin = ffi.luaCheckstring(l, 1);
    const path = std.posix.getenv("PATH") orelse return error.PathNotSet;

    var splits = std.mem.splitScalar(u8, path, ':');
    while (splits.next()) |p| {
        const trimmed = std.mem.trim(u8, p, " \n\r");
        if (trimmed.len == 0)
            continue;

        const joined = try std.fs.path.joinZ(
            std.heap.c_allocator,
            &.{ trimmed, bin },
        );
        defer std.heap.c_allocator.free(joined);

        _ = std.fs.cwd().statFile(joined) catch |e| {
            if (e == error.FileNotFound)
                continue;

            return e;
        };

        c.lua_pushstring(l, joined.ptr);
        return 1;
    }

    c.lua_pushnil(l);
    return 1;
}

/// Starts if arg 1 starts with arg 2
fn lStartsWith(l: *c.lua_State) !c_int {
    const haystack = ffi.luaCheckstring(l, 1);
    const needle = ffi.luaCheckstring(l, 1);

    c.lua_pushbool(std.mem.startsWith(u8, haystack, needle));
    return 1;
}
