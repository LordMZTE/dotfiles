const std = @import("std");
const znvim = @import("znvim");
const nvim = @import("nvim");

const opts = @import("opts");

const log = std.log.scoped(.options);

const opt = znvim.OptionValue.of;

/// Initializes neovim options.
pub fn initOptions() !void {
    var buf: [512]u8 = undefined;

    // Shell (defaults to mzteinit since that's my login shell)
    try opt("nu").setLog("shell", .both);

    try cmd("syntax on");

    // Quicker updatetime
    try opt(1000).setLog("updatetime", .both);

    // Indentation
    try opt(4).setLog("tabstop", .both);
    try opt(4).setLog("shiftwidth", .both);
    try opt(true).setLog("expandtab", .both);

    // Search
    try opt(true).setLog("ignorecase", .both);
    try opt(true).setLog("smartcase", .both);

    // Window Config
    try opt("100").setLog("colorcolumn", .both);
    try opt(100).setLog("textwidth", .both);
    try opt(true).setLog("cursorcolumn", .both);
    try opt(true).setLog("cursorline", .both);
    // The reason we're not getting this from confgen is that nvim-qt (which I want to replace, but
    // every other GUI is broken in some way) does not use fontconfig like a normal person but
    // instead some dumb Qt font naming where the font has a completely different name for whatever
    // reason.
    try opt("IosevkaTerm Nerd Font Mono:h12").setLog("guifont", .both);
    try opt("a").setLog("mouse", .both);
    try opt(true).setLog("number", .both);
    try opt(true).setLog("relativenumber", .both);
    try opt(10).setLog("scrolloff", .both);
    try opt(true).setLog("termguicolors", .both);

    // Folds
    try opt(2).setLog("conceallevel", .both);

    // Cursor
    try opt(
        "n-v-c-sm:block," ++ // Block cursor in normal-like modes
            "i-ci-ve:ver25," ++ // Vertical bar in insert-like modes
            "r-cr-o:hor20," ++ // Horizontal bar in replac-like modes
            "i-o-r-c-ci-cr-t:blinkon500-blinkoff500-blinkwait500-Cursor", // Blink in insert-like modes
    ).setLog("guicursor", .both);

    // Disable unwanted filetype mappings
    setVar("g:no_plugin_maps", .{ .bool = true });

    // Disable automatic formatting of Zig code (this is on by default!!!)
    setVar("g:zig_fmt_autosave", .{ .bool = false });

    // Other settings
    try cmd("filetype plugin on");

    // Disable garbage providers
    for ([_][]const u8{
        "python",
        "python3",
        "ruby",
        "perl",
        "node",
    }) |garbage| {
        const var_name = try std.fmt.bufPrintZ(&buf, "g:loaded_{s}_provider", .{garbage});
        setVar(var_name, .{ .bool = false });
    }

    // Neovide
    setVar("g:neovide_opacity", .{ .float = 0.9 });
    setVar("g:neovide_cursor_smooth_blink", .{ .bool = true });
    {
        const cursor_vfx = nvim.tv_list_alloc(2);
        for ([_][]const u8{ "railgun", "wireframe" }) |str| {
            nvim.tv_list_append_string(cursor_vfx, str.ptr, @intCast(str.len));
        }

        const key = "g:neovide_cursor_vfx_mode";
        var val = nvim.typval_T{
            .v_type = nvim.VAR_LIST,
            .v_lock = nvim.VAR_UNLOCKED,
            .vval = .{ .v_list = cursor_vfx },
        };
        nvim.set_var(key.ptr, key.len, &val, true);
    }
}

fn setVar(key: [:0]const u8, value: znvim.TypVal) void {
    var val = value.toNvim();
    nvim.set_var(key, key.len, &val, true);
}

fn cmd(cmd_s: [*:0]const u8) !void {
    if (nvim.do_cmdline_cmd(cmd_s) != nvim.OK) {
        return error.ExecCmd;
    }
}
