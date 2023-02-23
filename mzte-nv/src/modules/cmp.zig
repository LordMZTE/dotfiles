const std = @import("std");
const ser = @import("../ser.zig");
const ffi = @import("../ffi.zig");
const c = ffi.c;

pub fn luaPush(l: *c.lua_State) void {
    ser.luaPushAny(l, .{
        .onTab = ffi.luaFunc(lOnTab),
    });
}

fn lOnTab(l: *c.lua_State) !c_int {
    // param 1 is the fallback function
    c.luaL_checktype(l, 1, c.LUA_TFUNCTION);

    // vim.api at idx 2
    c.lua_getglobal(l, "vim");
    c.lua_getfield(l, -1, "api");
    c.lua_remove(l, 2);

    // cmp module on stack idx 3
    c.lua_getglobal(l, "require");
    c.lua_pushstring(l, "cmp");
    c.lua_call(l, 1, 1);

    // luasnip module on stack idx 4
    c.lua_getglobal(l, "require");
    c.lua_pushstring(l, "luasnip");
    c.lua_call(l, 1, 1);

    // call cmp.visible()
    c.lua_getfield(l, 3, "visible");
    c.lua_call(l, 0, 1);
    const cmp_visible = c.lua_toboolean(l, -1);
    c.lua_pop(l, 1);

    if (cmp_visible != 0) {
        // call cmp.select_next_item()
        c.lua_getfield(l, 3, "select_next_item");
        c.lua_call(l, 0, 0);
    } else if (blk: {
        // call luasnip.expand_or_jumpable()
        c.lua_getfield(l, 4, "expand_or_jumpable");
        c.lua_call(l, 0, 1);
        const b = c.lua_toboolean(l, -1) != 0;
        c.lua_pop(l, 1);
        break :blk b;
    }) {
        // call luasnip.expand_or_jump()
        c.lua_getfield(l, 4, "expand_or_jump");
        c.lua_call(l, 0, 0);
    } else if (blk: {
        // in this if, we check if the char before the cursor is NOT a whitespace,
        // in which case we have cmp complete.

        // call vim.api.nvim_win_get_cursor(0), returns the cursor position in the current buf
        // in an array table with 2 values
        c.lua_getfield(l, 2, "nvim_win_get_cursor");
        c.lua_pushinteger(l, 0);
        c.lua_call(l, 1, 1);

        c.lua_rawgeti(l, -1, 1);
        const cursor_line = c.lua_tointeger(l, -1);
        c.lua_pop(l, 1);

        c.lua_rawgeti(l, -1, 2);
        const cursor_col = c.lua_tointeger(l, -1);
        c.lua_pop(l, 2);

        // If the cursor column is 0, that counts as a whitespace.
        if (cursor_col == 0) {
            break :blk false;
        }

        // call vim.api.nvim_buf_get_lines(0, line - 1, line, true)
        // returns in array containing the line the cursor is at
        c.lua_getfield(l, 2, "nvim_buf_get_lines");
        c.lua_pushinteger(l, 0);
        c.lua_pushinteger(l, cursor_line - 1);
        c.lua_pushinteger(l, cursor_line);
        c.lua_pushboolean(l, 1);
        c.lua_call(l, 4, 1);

        // get the line
        c.lua_rawgeti(l, -1, 1);
        const line = ffi.luaToString(l, -1);

        // char at the cursor is NOT whitespace
        const b = std.mem.indexOfScalar(
            u8,
            " \t\n",
            line[@intCast(usize, cursor_col) - 1],
        ) == null;

        // remove the string and the string array from the stack
        c.lua_pop(l, 2);

        break :blk b;
    }) {
        // call cmp.complete()
        c.lua_getfield(l, 3, "complete");
        c.lua_call(l, 0, 0);
    } else {
        // call fallback function
        c.lua_pushvalue(l, 1);
        c.lua_call(l, 0, 0);
    }

    // clear stack
    c.lua_settop(l, 0);
    return 0;
}
