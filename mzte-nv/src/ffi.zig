const std = @import("std");

pub const c = @cImport({
    @cInclude("lua.h");
    @cInclude("lualib.h");
    @cInclude("lauxlib.h");
});

/// Generates a wrapper function with error handling for a lua CFunction
pub fn luaFunc(comptime func: fn (*c.lua_State) anyerror!c_int) c.lua_CFunction {
    return &struct {
        fn f(l: ?*c.lua_State) callconv(.C) c_int {
            return func(l.?) catch |e| {
                var buf: [128]u8 = undefined;
                const err_s = std.fmt.bufPrintZ(
                    &buf,
                    "Zig Error: {s}",
                    .{@errorName(e)},
                ) catch unreachable;
                c.lua_pushstring(l, err_s.ptr);
                _ = c.lua_error(l);
                unreachable;
            };
        }
    }.f;
}
