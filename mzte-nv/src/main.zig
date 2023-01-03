const std = @import("std");
const ffi = @import("ffi.zig");
const ser = @import("ser.zig");
const c = ffi.c;

pub const version = "1.1.0";

const modules = struct {
    const cmp = @import("modules/cmp.zig");
    const compile = @import("modules/compile.zig");
    const jdtls = @import("modules/jdtls.zig");
    const utils = @import("modules/utils.zig");
};

var lua_state: ?*c.lua_State = null;

pub fn log(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    // if there's no lua state, we can't invoke nvim notifications.
    const l = lua_state orelse return;

    const stacktop = c.lua_gettop(l);
    defer c.lua_settop(l, stacktop);

    var fmtbuf: [2048]u8 = undefined;

    c.lua_getglobal(l, "vim");
    c.lua_getfield(l, -1, "log");
    c.lua_getfield(l, -1, "levels");
    switch (level) {
        .err => c.lua_getfield(l, -1, "ERROR"),
        .warn => c.lua_getfield(l, -1, "WARN"),
        .info => c.lua_getfield(l, -1, "INFO"),
        .debug => c.lua_getfield(l, -1, "DEBUG"),
    }

    const vim_lvl = c.lua_tointeger(l, -1);
    c.lua_pop(l, 3);

    c.lua_getfield(l, -1, "notify");

    const msg = std.fmt.bufPrintZ(&fmtbuf, format, args) catch return;
    c.lua_pushstring(l, msg.ptr);

    c.lua_pushinteger(l, vim_lvl);

    const title = std.fmt.bufPrintZ(
        &fmtbuf,
        "MZTE-NV ({s})",
        .{@tagName(scope)},
    ) catch return;
    ser.luaPushAny(l, .{
        .title = title,
    });
    c.lua_call(l, 3, 0);
}

pub const log_level = .debug;

export fn luaopen_mzte_nv(l_: ?*c.lua_State) c_int {
    lua_state = l_;
    const l = l_.?;
    ser.luaPushAny(l, .{
        .onInit = ffi.luaFunc(lOnInit),
        .cmp = modules.cmp,
        .compile = modules.compile,
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

    std.log.info(
        "MZTE-NV v{s} Initialized on NVIM v{}.{}.{}{s}",
        .{ version, major, minor, patch, prerelease },
    );
    return 0;
}
