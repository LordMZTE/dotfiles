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
    try opt("100").setLog("textwidth", .both);
    try opt(true).setLog("cursorcolumn", .both);
    try opt(true).setLog("cursorline", .both);
    try opt(try std.fmt.bufPrintZ(&buf, "{s}:h10", .{opts.font})).setLog("guifont", .both);
    try opt("a").setLog("mouse", .both);
    try opt(true).setLog("number", .both);
    try opt(true).setLog("relativenumber", .both);
    try opt(10).setLog("scrolloff", .both);
    try opt(true).setLog("termguicolors", .both);

    // Folds
    try opt(2).setLog("conceallevel", .both);

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
    setVar("g:neovide_transparency", .{ .float = 0.9 });
    setVar("g:neovide_cursor_vfx_mode", .{ .string = @constCast("wireframe") });
}

fn setVar(key: [:0]const u8, value: znvim.TypVal) void {
    var val = value.toNvim();
    nvim.set_var(key, key.len, &val, false);
}

fn cmd(cmd_s: [*:0]const u8) !void {
    if (nvim.do_cmdline_cmd(cmd_s) != nvim.OK) {
        return error.ExecCmd;
    }
}
