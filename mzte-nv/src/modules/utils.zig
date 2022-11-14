const std = @import("std");
const ser = @import("../ser.zig");
const ffi = @import("../ffi.zig");
const c = ffi.c;

pub fn luaPush(l: *c.lua_State) void {
    ser.luaPushAny(l, .{
        .findInPath = ffi.luaFunc(lFindInPath),
    });
}

/// This is basically a reimplementation of `which`.
fn lFindInPath(l: *c.lua_State) !c_int {
    const path = std.os.getenv("PATH") orelse return error.PathNotSet;
    const bin = c.luaL_checklstring(l, 1, null);

    var splits = std.mem.split(u8, path, ":");
    while (splits.next()) |p| {
        const trimmed = std.mem.trim(u8, p, " \n\r");
        if (trimmed.len == 0)
            continue;

        const joined = try std.fs.path.joinZ(
            std.heap.c_allocator,
            &.{ trimmed, std.mem.span(bin) },
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
