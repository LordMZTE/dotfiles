//! Module for tree-sitter node actions
const std = @import("std");
const ser = @import("../ser.zig");
const ffi = @import("../ffi.zig");
const c = ffi.c;

pub fn luaPush(l: *c.lua_State) void {
    ser.luaPushAny(l, .{
        .zigToggleMutability = ffi.luaFunc(lZigToggleMutability),
        .intToHex = ffi.luaFunc(lIntToHex),
        .intToDec = ffi.luaFunc(lIntToDec),
        .intToggle = ffi.luaFunc(lIntToggle),
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
    var liter = std.mem.splitScalar(u8, out, '\n');
    var idx: c_int = 1;
    while (liter.next()) |line| {
        ffi.luaPushString(l, line);
        c.lua_rawseti(l, -2, idx);
        idx += 1;
    }

    return 1;
}

/// Given a hex number literal, determine the index where the actual number starts.
/// Returns 0 if this isn't a hex number.
fn hexStartIdx(s: []const u8) u2 {
    if (s.len < 3)
        return 0;

    const offset: u2 = if (s[0] == '-') 1 else 0;

    if (s.len - offset < 3 or !std.mem.eql(u8, "0x", s[offset..][0..2]))
        return 0;

    return 2 + offset;
}

fn lIntToHex(l: *c.lua_State) !c_int {
    const inp = ffi.luaCheckstring(l, 1);
    const parsed = try std.fmt.parseInt(i64, inp, 10);

    var buf: [128]u8 = undefined;
    ffi.luaPushString(
        l,
        if (parsed < 0)
            try std.fmt.bufPrint(&buf, "-0x{x}", .{-parsed})
        else
            try std.fmt.bufPrint(&buf, "0x{x}", .{parsed}),
    );
    return 1;
}

fn lIntToDec(l: *c.lua_State) !c_int {
    const inp = ffi.luaCheckstring(l, 1);
    const start_idx = hexStartIdx(inp);
    if (start_idx == 0)
        return error.InvalidHex;

    const parsed = try std.fmt.parseInt(
        i64,
        inp[start_idx..],
        16,
    ) * @as(i2, if (start_idx == 3) -1 else 1);

    var buf: [128]u8 = undefined;
    ffi.luaPushString(l, try std.fmt.bufPrint(&buf, "{d}", .{parsed}));
    return 1;
}

fn lIntToggle(l: *c.lua_State) !c_int {
    const inp = ffi.luaCheckstring(l, 1);
    for (inp) |char| {
        // return input for floats
        if (char == '.' or char == 'f' or char == 'f') {
            c.lua_pushvalue(l, 1);
            return 1;
        }
    }

    if (hexStartIdx(inp) != 0) {
        return try lIntToDec(l);
    } else {
        return try lIntToHex(l);
    }
}
