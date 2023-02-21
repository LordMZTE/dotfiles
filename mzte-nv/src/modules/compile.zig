//! Module for compiling lua files using luajit
//! and mzte-nv-compiler.
const std = @import("std");
const ser = @import("../ser.zig");
const ffi = @import("../ffi.zig");
const c = ffi.c;
const compiler = @import("../compiler.zig");

pub fn luaPush(l: *c.lua_State) void {
    ser.luaPushAny(l, .{
        .compilePath = ffi.luaFunc(lCompilePath),
    });
}

fn lCompilePath(l: *c.lua_State) !c_int {
    const path = c.luaL_checklstring(l, 1, null);
    try compiler.doCompile(std.mem.span(path), std.heap.c_allocator);
    return 0;
}
