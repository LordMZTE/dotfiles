const std = @import("std");
const opts = @import("opts");

const ffi = @import("../ffi.zig");
const ser = @import("../ser.zig");
const c = ffi.c;

const fnl_regkey = "mzte-nv-fnl";

pub fn luaPush(l: *c.lua_State) void {
    ser.luaPushAny(l, .{
        .eval = ffi.luaFunc(lEval),
        .fnlMod = ffi.luaFunc(lFnlMod),
    });
}

fn loadFennel(l: *c.lua_State) !void {
    c.lua_getfield(l, c.LUA_REGISTRYINDEX, fnl_regkey);
    if (!c.lua_isnil(l, -1)) {
        return;
    }
    c.lua_pop(l, 1);

    std.log.debug("loading fennel", .{});

    if (c.luaL_loadfile(l, opts.@"fennel.lua" orelse "/usr/share/lua/5.4/fennel.lua") != 0) {
        return error.FennelLoad;
    }

    if (c.lua_pcall(l, 0, 1, 0) != 0) {
        std.log.err("Failed to load fennel compiler: {s}", .{ffi.luaToString(l, -1)});
        return error.FennelLoad;
    }

    c.lua_pushvalue(l, -1);
    c.lua_setfield(l, c.LUA_REGISTRYINDEX, fnl_regkey);
}

fn lFnlMod(l: *c.lua_State) !c_int {
    try loadFennel(l);
    return 1;
}

fn lEval(l: *c.lua_State) !c_int {
    const argc = c.lua_gettop(l);
    try loadFennel(l);
    c.lua_getfield(l, -1, "eval");

    var i: c_int = 1;
    while (i <= argc) : (i += 1) {
        c.lua_pushvalue(l, i);
    }

    c.lua_call(l, argc, c.LUA_MULTRET);
    return c.lua_gettop(l) - (argc + 1);
}
