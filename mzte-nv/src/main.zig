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
    const cpbuf = @import("modules/cpbuf.zig");
    const fennel = @import("modules/fennel.zig");
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

        var dict = znvim.Dictionary{ .alloc = std.heap.c_allocator };
        defer dict.deinit();

        dict.push(@constCast("title"), znvim.nvimObject(@as([]u8, title))) catch return;
        // noice notficitaions recognize this and show in the mini view instead of notifs
        dict.push(@constCast("mzte_nv_mini"), comptime znvim.nvimObject(true)) catch return;

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
        .cpbuf = modules.cpbuf,
        .fennel = modules.fennel,
        .jdtls = modules.jdtls,
        .tsn_actions = modules.tsn_actions,
        .utils = modules.utils,
    });
    return 1;
}

fn lOnInit(l: *c.lua_State) !c_int {
    _ = l;
    try @import("options.zig").initOptions();

    std.log.info(
        "MZTE-NV v{s} Initialized on NVIM v{s}",
        .{ version, nvim.longVersion },
    );
    return 0;
}
