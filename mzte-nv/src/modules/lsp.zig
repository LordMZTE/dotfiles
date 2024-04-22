//! Module for nvim-lsp related utilities
const std = @import("std");
const ser = @import("../ser.zig");
const ffi = @import("../ffi.zig");
const c = ffi.c;

pub fn luaPush(l: *c.lua_State) void {
    ser.luaPushAny(l, .{
        .onAttach = ffi.luaFunc(lOnAttach),
    });
}

fn lOnAttach(l: *c.lua_State) !c_int {
    c.luaL_checkany(l, 1);
    const bufnr = c.luaL_checknumber(l, 2);

    const has_inlay_hints = hints: {
        c.lua_getfield(l, 1, "server_capabilities");
        defer c.lua_pop(l, 1);
        if (c.lua_isnil(l, -1)) break :hints false;
        c.lua_getfield(l, -1, "inlayHintProvider");
        defer c.lua_pop(l, 1);
        break :hints c.lua_toboolean(l, -1) != 0;
    };

    if (has_inlay_hints) {
        // func: vim.lsp.inlay_hint.enable
        c.lua_getglobal(l, "vim");
        c.lua_getfield(l, -1, "lsp");
        c.lua_getfield(l, -1, "inlay_hint");
        c.lua_getfield(l, -1, "enable");

        // arg 1: true
        c.lua_pushboolean(l, 1);

        // arg 2: table w/ bufnr
        c.lua_createtable(l, 0, 1);
        c.lua_pushnumber(l, bufnr);
        c.lua_setfield(l, -2, "bufnr");

        c.lua_call(l, 2, 0);

        c.lua_pop(l, 3);
    }

    return 0;
}
