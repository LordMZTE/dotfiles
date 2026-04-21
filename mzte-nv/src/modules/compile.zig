//! Module for compiling lua files using luajit
//! and mzte-nv-compiler.
const std = @import("std");
const ffi = @import("lualib");
const com = @import("common");
const c = ffi.c;

const compiler = @import("../compiler.zig");
const iomod = @import("../io.zig");

pub fn luaPush(l: *c.lua_State) void {
    ffi.ser.luaPushAny(l, .{
        .compilePath = ffi.luaFunc(lCompilePath),
    });
}

fn lCompilePath(l: *c.lua_State) !c_int {
    const path = ffi.luaCheckstring(l, 1);
    const io = iomod.getIo(l);
    try compiler.doCompile(path, io, std.heap.c_allocator, com.cGetenv(compiler.fnl_env_var));
    return 0;
}
