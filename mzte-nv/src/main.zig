const std = @import("std");
const ffi = @import("ffi.zig");
const ser = @import("ser.zig");
const c = ffi.c;

pub const version = "0.3.0";

const modules = struct {
    const cmp = @import("modules/cmp.zig");
    const jdtls = @import("modules/jdtls.zig");
    const utils = @import("modules/utils.zig");
};

export fn luaopen_mzte_nv(l_: ?*c.lua_State) c_int {
    const l = l_.?;
    ser.luaPushAny(l, .{
        .onInit = ffi.luaFunc(lOnInit),
        .cmp = modules.cmp,
        .jdtls = modules.jdtls,
        .utils = modules.utils,
    });
    return 1;
}

fn lOnInit(l: *c.lua_State) !c_int {
    c.lua_getglobal(l, "vim"); // 1
    c.lua_getfield(l, 1, "version");
    c.lua_call(l, 0, 1); // 2

    c.lua_getfield(l, 2, "major");
    const major = c.lua_tointeger(l, -1);

    c.lua_getfield(l, 2, "minor");
    const minor = c.lua_tointeger(l, -1);

    c.lua_getfield(l, 2, "patch");
    const patch = c.lua_tointeger(l, -1);

    c.lua_getfield(l, 2, "prerelease");
    const prerelease = if (c.lua_toboolean(l, -1) != 0) " (prerelease)" else "";

    c.lua_settop(l, 1);

    var buf: [128]u8 = undefined;
    const s = try std.fmt.bufPrintZ(
        &buf,
        "MZTE-NV v{s} Initialized on NVIM v{}.{}.{}{s}",
        .{ version, major, minor, patch, prerelease },
    );

    c.lua_getfield(l, 1, "notify");
    c.lua_pushstring(l, s.ptr);
    c.lua_call(l, 1, 0);

    return 0;
}
