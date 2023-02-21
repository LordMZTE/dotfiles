//! Module for tree-sitter node actions
const std = @import("std");
const ser = @import("../ser.zig");
const ffi = @import("../ffi.zig");
const c = ffi.c;

pub fn luaPush(l: *c.lua_State) void {
    ser.luaPushAny(l, .{
        .zigToggleMutability = ffi.luaFunc(lZigToggleMutability),
    });
}

fn lZigToggleMutability(l: *c.lua_State) !c_int {
    const inp = ffi.luaCheckstring(l, 1);

    // this has got to be enough for any halfway reasonable variable declaration
    var buf: [1024 * 4]u8 = undefined;
    const out = if (std.mem.startsWith(u8, inp, "var"))
        try std.fmt.bufPrint(&buf, "const{s}", .{inp[3..]})
    else if (std.mem.startsWith(u8, inp, "const"))
        try std.fmt.bufPrint(&buf, "var{s}", .{inp[5..]})
    else
        inp;

    // split into lines
    c.lua_newtable(l);
    var liter = std.mem.split(u8, out, "\n");
    var idx: c_int = 1;
    while (liter.next()) |line| {
        ffi.luaPushString(l, line);
        c.lua_rawseti(l, -2, idx);
        idx += 1;
    }

    return 1;
}
