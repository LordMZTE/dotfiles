const std = @import("std");
const nvim = @import("nvim");
const znvim = @import("znvim");
const ffi = @import("ffi.zig");
const ser = @import("ser.zig");
const c = ffi.c;

pub const version = "1.2.0";

const modules = struct {
    const cmp = @import("modules/cmp.zig");
    const compile = @import("modules/compile.zig");
    const jdtls = @import("modules/jdtls.zig");
    const tsn_actions = @import("modules/tsn_actions.zig");
    const utils = @import("modules/utils.zig");
};

pub const std_options = struct {
    pub fn logFn(
        comptime level: std.log.Level,
        comptime scope: @TypeOf(.EnumLiteral),
        comptime format: []const u8,
        args: anytype,
    ) void {
        var msg_buf: [512]u8 = undefined;
        const msg = std.fmt.bufPrintZ(&msg_buf, format, args) catch return;

        var title_buf: [512]u8 = undefined;
        const title = std.fmt.bufPrintZ(
            &title_buf,
            "MZTE-NV ({s})",
            .{@tagName(scope)},
        ) catch return;

        const lvl = switch (level) {
            .debug => nvim.LOGLVL_DBG,
            .info => nvim.LOGLVL_INF,
            .warn => nvim.LOGLVL_WRN,
            .err => nvim.LOGLVL_ERR,
        };

        var dict = znvim.Dictionary{.alloc = std.heap.c_allocator};
        defer dict.deinit();

        dict.push(@constCast("title"), znvim.nvimObject(@as([]u8, title))) catch return;

        var e = znvim.Error{};
        _ = nvim.nvim_notify(
            znvim.nvimString(msg),
            lvl,
            dict.dict,
            &e.err,
        );
    }

    pub const log_level = .debug;
};

export fn luaopen_mzte_nv(l_: ?*c.lua_State) c_int {
    const l = l_.?;
    ser.luaPushAny(l, .{
        .onInit = ffi.luaFunc(lOnInit),
        .cmp = modules.cmp,
        .compile = modules.compile,
        .jdtls = modules.jdtls,
        .tsn_actions = modules.tsn_actions,
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
