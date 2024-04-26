const std = @import("std");
const nvim = @import("nvim");
const znvim = @import("znvim");
const opts = @import("opts");

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
    const lsp = @import("modules/lsp.zig");
    const lsp_progress = @import("modules/lsp_progress.zig");
    const telescope = @import("modules/telescope.zig");
    const tsn_actions = @import("modules/tsn_actions.zig");
    const utils = @import("modules/utils.zig");
};

pub const std_options = std.Options{
    .logFn = struct {
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
    }.logFn,

    .log_level = .debug,
};

const reg_key = "mzte-nv-reg";

export fn luaopen_mzte_nv(l_: ?*c.lua_State) c_int {
    const l = l_.?;
    ser.luaPushAny(l, .{
        .reg = struct {
            pub fn luaPush(lua: *c.lua_State) void {
                c.lua_getfield(lua, c.LUA_REGISTRYINDEX, reg_key);

                // registry uninitialized
                if (c.lua_isnil(lua, -1)) {
                    c.lua_pop(lua, 1);
                    c.lua_newtable(lua);
                    c.lua_pushvalue(lua, -1);
                    c.lua_setfield(lua, c.LUA_REGISTRYINDEX, reg_key);
                }
            }
        },

        .onInit = ffi.luaFunc(lOnInit),

        .cmp = modules.cmp,
        .compile = modules.compile,
        .cpbuf = modules.cpbuf,
        .fennel = modules.fennel,
        .jdtls = modules.jdtls,
        .lsp = modules.lsp,
        .lsp_progress = modules.lsp_progress,
        .telescope = modules.telescope,
        .tsn_actions = modules.tsn_actions,
        .utils = modules.utils,
    });
    return 1;
}

fn lOnInit(l: *c.lua_State) !c_int {
    try @import("options.zig").initOptions();

    c.lua_getfield(l, c.LUA_REGISTRYINDEX, reg_key);
    defer c.lua_pop(l, 1);
    inline for (.{ "nvim_plugins", "tree_sitter_parsers", "nvim_tools" }) |fname| {
        if (@field(opts, fname)) |x| {
            ffi.luaPushString(l, x);
            c.lua_setfield(l, -2, fname);
        }
    }

    ser.luaPushAny(l, [_][]const u8{ "⬖", "⬘", "⬗", "⬙" });
    c.lua_setfield(l, -2, "spinner");

    std.log.info(
        "MZTE-NV v{s} Initialized on {s}",
        .{ version, nvim.longVersion },
    );
    return 0;
}
