const std = @import("std");
const c = ffi.c;
const common = @import("common");

const ffi = @import("lualib");

pub fn luaPush(l: *c.lua_State) void {
    ffi.ser.luaPushAny(l, .{
        .formatSeries = ffi.luaFunc(lFormatSeries),
        .formatClient = ffi.luaFunc(lFormatClient),
    });
}

fn fmtEscapedFn(s: []const u8, writer: *std.Io.Writer) !void {
    for (s) |ch| {
        if (ch == '%')
            try writer.writeAll("%%")
        else
            try writer.writeByte(ch);
    }
}

fn fmtEscaped(s: []const u8) std.fmt.Alt([]const u8, fmtEscapedFn) {
    return .{ .data = s };
}

fn lFormatSeries(l: *c.lua_State) !c_int {
    const title = if (c.lua_isnil(l, 1)) null else ffi.luaCheckstring(l, 1);
    const message = if (c.lua_isnil(l, 2)) null else ffi.luaCheckstring(l, 2);
    const percentage = c.lua_tointeger(l, 3);
    const done = c.lua_toboolean(l, 4) != 0;

    var buf: [1024]u8 = undefined;
    var bufw = std.Io.Writer.fixed(&buf);
    var del = common.DelimitedWriter{ .writer = &bufw, .delimiter = ' ' };

    const msg_is_title = title != null and message != null and std.mem.eql(u8, title.?, message.?);

    if (title) |t|
        try del.print("%#Title#{f}", .{fmtEscaped(t)});

    if (message) |m|
        if (!msg_is_title)
            try del.print("%#ModeMsg#{f}", .{fmtEscaped(m)});

    if (percentage != 0)
        try del.print("%#NONE#(%#Number#{d}%%%#NONE#)", .{percentage});

    try del.push(if (done) "%#DiagnosticOk#󰸞" else "%#DiagnosticInfo#");

    try del.writer.writeAll("%#NONE#");

    ffi.luaPushString(l, bufw.buffered());
    return 1;
}

fn lFormatClient(l: *c.lua_State) !c_int {
    const client_name = ffi.luaCheckstring(l, 1);
    const spinner = ffi.luaCheckstring(l, 2);
    // 3: array of series messages
    c.luaL_checktype(l, 3, c.LUA_TTABLE);

    var buf: [1024]u8 = undefined;
    var bufw = std.Io.Writer.fixed(&buf);
    var del = common.DelimitedWriter{ .writer = &bufw, .delimiter = ' ' };

    try del.print("%#Special#[{s}] %#Comment#{s}", .{ client_name, spinner });

    const max_msgs = 2;

    const nmsgs = c.lua_objlen(l, 3);
    const nshown = @min(nmsgs, max_msgs);
    for (1..nshown + 1) |i| {
        _ = c.lua_rawgeti(l, 3, @intCast(i));
        defer c.lua_pop(l, 1);

        const msg = ffi.luaToString(l, -1);
        try del.push(msg);
        if (i != nshown) {
            try del.writer.writeAll("%#Operator#,");
        }
    }

    if (nmsgs > max_msgs) {
        try del.push("%#Comment#󰇘");
    }

    ffi.luaPushString(l, bufw.buffered());
    return 1;
}
