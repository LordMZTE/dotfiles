const std = @import("std");

pub const c = @cImport({
    @cInclude("lua.h");
    @cInclude("lualib.h");
    @cInclude("lauxlib.h");
});

/// Generates a wrapper function with error handling for a lua CFunction
/// func should be `fn(*c.lua_State) !c_int` ()
pub fn luaFunc(comptime func: anytype) c.lua_CFunction {
    return &struct {
        fn f(l: ?*c.lua_State) callconv(.C) c_int {
            return func(l.?) catch |e| {
                var buf: [1024 * 4]u8 = undefined;
                var fbs = std.io.fixedBufferStream(&buf);
                fbs.writer().print("Zig Error: {s}\n", .{@errorName(e)}) catch @panic("OOM");
                if (@errorReturnTrace()) |ert| {
                    std.debug.writeStackTrace(
                        ert.*,
                        fbs.writer(),
                        std.debug.getSelfDebugInfo() catch @panic("WTF"),
                        .no_color,
                    ) catch @panic("OOM");
                }

                luaPushString(l, fbs.getWritten());
                _ = c.lua_error(l);
                unreachable;
            };
        }
    }.f;
}

/// A thin wrapper around luaL_checklstring that uses the length parameter to return a slice.
pub fn luaCheckstring(l: ?*c.lua_State, idx: c_int) []const u8 {
    var len: usize = 0;
    return c.luaL_checklstring(l, idx, &len)[0..len];
}

pub fn luaPushString(l: ?*c.lua_State, s: []const u8) void {
    c.lua_pushlstring(l, s.ptr, s.len);
}

pub fn luaToString(l: ?*c.lua_State, idx: c_int) []const u8 {
    var len: usize = 0;
    return c.lua_tolstring(l, idx, &len)[0..len];
}
