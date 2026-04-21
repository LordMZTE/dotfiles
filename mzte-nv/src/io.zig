const std = @import("std");
const ffi = @import("lualib");
const c = ffi.c;

const io_reg_key = "mzte-nv-io";

pub fn initIo(l: *c.lua_State) void {
    const ioptr: *std.Io.Threaded = @ptrCast(@alignCast(
        c.lua_newuserdata(l, @sizeOf(std.Io.Threaded)),
    ));
    ioptr.* = .init_single_threaded;

    const Metatable = struct {
        fn lGc(l_: *c.lua_State) !c_int {
            std.debug.assert(c.lua_gettop(l_) == 1);
            const io: *std.Io.Threaded = @ptrCast(@alignCast(c.lua_touserdata(l_, 1)));
            io.deinit();
            return 0;
        }
    };

    c.lua_createtable(l, 0, 1);
    c.lua_pushcfunction(l, ffi.luaFunc(Metatable.lGc));
    c.lua_setfield(l, -2, "__gc");

    _ = c.lua_setmetatable(l, -2);

    c.lua_setfield(l, c.LUA_REGISTRYINDEX, io_reg_key);
}

pub fn getIo(l: *c.lua_State) std.Io {
    c.lua_getfield(l, c.LUA_REGISTRYINDEX, io_reg_key);
    const ioptr: *std.Io.Threaded = @ptrCast(@alignCast(c.lua_touserdata(l, -1)));
    c.lua_pop(l, 1);
    return ioptr.io();
}
