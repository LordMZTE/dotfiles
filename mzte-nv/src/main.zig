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
    const inlay_hint = @import("modules/inlay_hint.zig");
    const jdtls = @import("modules/jdtls.zig");
    const lsp_progress = @import("modules/lsp_progress.zig");
    const telescope = @import("modules/telescope.zig");
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

            const l: *c.lua_State = @ptrCast(nvim.get_global_lstate());
            const top = c.lua_gettop(l);
            c.lua_settop(l, top);

            // This used to invoke nvim.nvim_notify, which is now not only deprecated, but does and
            // always has done exactly this.
            c.lua_getglobal(l, "vim");
            c.lua_getfield(l, -1, "notify");
            ffi.luaPushString(l, msg);
            c.lua_pushinteger(l, lvl);
            ser.luaPushAny(l, .{ .title = title });
            _ = c.lua_pcall(l, 3, 0, 0);
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
        .inlay_hint = modules.inlay_hint,
        .jdtls = modules.jdtls,
        .lsp_progress = modules.lsp_progress,
        .telescope = modules.telescope,
        .utils = modules.utils,
    });
    return 1;
}

fn lOnInit(l: *c.lua_State) !c_int {
    try @import("options.zig").initOptions();

    c.lua_getfield(l, c.LUA_REGISTRYINDEX, reg_key);
    defer c.lua_pop(l, 1);

    if (@hasField(@TypeOf(opts), "nix")) {
        inline for (.{ "nvim_plugins", "nvim_tools" }) |fname| {
            ffi.luaPushString(l, @field(opts.nix, fname));
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
