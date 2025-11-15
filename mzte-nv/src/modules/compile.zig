//! Module for compiling lua files using luajit
//! and mzte-nv-compiler.
const std = @import("std");
const ffi = @import("lualib");
const c = ffi.c;
const compiler = @import("../compiler.zig");

pub fn luaPush(l: *c.lua_State) void {
    ffi.ser.luaPushAny(l, .{
        .compilePath = ffi.luaFunc(lCompilePath),
    });
}

fn lCompilePath(l: *c.lua_State) !c_int {
    const path = ffi.luaCheckstring(l, 1);
    try compiler.doCompile(path, std.heap.c_allocator);
    return 0;
}
