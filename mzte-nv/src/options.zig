const std = @import("std");
const znvim = @import("znvim");
const nvim = @import("nvim");

const opts = @import("opts");

const log = std.log.scoped(.options);

/// Initializes neovim options.
pub fn initOptions() !void {
    var buf: [512]u8 = undefined;

    // Shell (defaults to mzteinit since that's my login shell)
    try setOption("shell", "fish");

    try cmd("syntax on");

    // Quicker updatetime
    try setOption("updatetime", 1000);

    // Indentation
    try setOption("tabstop", 4);
    try setOption("shiftwidth", 4);
    try setOption("expandtab", true);

    // Search
    try setOption("ignorecase", true);
    try setOption("smartcase", true);

    // Window Config
    try setOption("colorcolumn", "100");
    try setOption("cursorcolumn", true);
    try setOption("cursorline", true);
    try setOption("guifont", try std.fmt.bufPrintZ(&buf, "{s}:h10", .{opts.font}));
    try setOption("mouse", "a");
    try setOption("number", true);
    try setOption("relativenumber", true);
    try setOption("scrolloff", 10);
    try setOption("termguicolors", true);

    // Folds
    try setOption("conceallevel", 2);

    // Disable unwanted filetype mappings
    setVar("g:no_plugin_maps", .{ .bool = true });

    // Disable automatic formatting of Zig code (this is on by default!!!)
    setVar("g:zig_fmt_autosave", .{ .bool = false });

    // Other settings
    try cmd("colorscheme dracula");
    try cmd("filetype plugin on");

    // Disable garbage providers
    for ([_][]const u8{
        "python",
        "python3",
        "ruby",
        "perl",
        "node",
    }) |garbage| {
        const opt = try std.fmt.bufPrintZ(&buf, "g:loaded_{s}_provider", .{garbage});
        setVar(opt, .{ .bool = false });
    }

    // Neovide
    setVar("g:neovide_transparency", .{ .float = 0.9 });
    setVar("g:neovide_cursor_vfx_mode", .{ .string = @constCast("wireframe") });
}

fn setOption(key: [*:0]const u8, value: anytype) !void {
    const Val = @TypeOf(value);
    const ret = switch (@typeInfo(Val)) {
        .Pointer => nvim.set_option_value(key, 0, value, 0),
        .Int, .ComptimeInt => nvim.set_option_value(key, value, null, 0),
        .Bool => nvim.set_option_value(key, @boolToInt(value), null, 0),
        else => @compileError("Unsupported value type: " ++ @typeName(Val)),
    };

    if (ret) |err| {
        log.err("Setting option: {s}", .{err});
        return error.SetOption;
    }
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
