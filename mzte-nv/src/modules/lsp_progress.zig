const std = @import("std");
const c = ffi.c;
const common = @import("common");

const ser = @import("../ser.zig");
const ffi = @import("../ffi.zig");

pub fn luaPush(l: *c.lua_State) void {
    ser.luaPushAny(l, .{
        .formatSeries = ffi.luaFunc(lFormatSeries),
        .formatClient = ffi.luaFunc(lFormatClient),
    });
}

fn fmtEscapedFn(
    s: []const u8,
    comptime _: []const u8,
    _: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    for (s) |ch| {
        if (ch == '%')
            try writer.writeAll("%%")
        else
            try writer.writeByte(ch);
    }
}

fn fmtEscaped(s: []const u8) std.fmt.Formatter(fmtEscapedFn) {
    return .{ .data = s };
}

fn lFormatSeries(l: *c.lua_State) !c_int {
    const title = if (c.lua_isnil(l, 1)) null else ffi.luaCheckstring(l, 1);
    const message = if (c.lua_isnil(l, 2)) null else ffi.luaCheckstring(l, 2);
    const percentage = c.lua_tointeger(l, 3);
    const done = c.lua_toboolean(l, 4) != 0;

    var buf = std.BoundedArray(u8, 1024).init(0) catch unreachable;
    var del = common.delimitedWriter(buf.writer(), ' ');

    const msg_is_title = title != null and message != null and std.mem.eql(u8, title.?, message.?);

    if (title) |t|
        try del.print("%#Title#{s}", .{fmtEscaped(t)});

    if (message) |m|
        if (!msg_is_title)
            try del.print("%#ModeMsg#{s}", .{fmtEscaped(m)});

    if (percentage != 0)
        try del.print("%#NONE#(%#Number#{d}%%%#NONE#)", .{percentage});

    try del.push(if (done) "%#DiagnosticOk#󰸞" else "%#DiagnosticInfo#");

    try del.writer.writeAll("%#NONE#");

    ffi.luaPushString(l, buf.slice());
    return 1;
}

fn lFormatClient(l: *c.lua_State) !c_int {
    const client_name = ffi.luaCheckstring(l, 1);
    const spinner = ffi.luaCheckstring(l, 2);
    // 3: array of series messages
    c.luaL_checktype(l, 3, c.LUA_TTABLE);

    var buf = std.BoundedArray(u8, 1024).init(0) catch unreachable;
    var del = common.delimitedWriter(buf.writer(), ' ');

    try del.print("%#Special#[{s}] %#Comment#{s}", .{ client_name, spinner });

    const nmsgs = c.lua_objlen(l, 3);
    for (1..nmsgs + 1) |i| {
        _ = c.lua_rawgeti(l, 3, @intCast(i));
        defer c.lua_pop(l, 1);

        const msg = ffi.luaToString(l, -1);
        try del.push(msg);
        if (i != nmsgs) {
            try del.writer.writeAll("%#Operator#,");
        }
    }

    ffi.luaPushString(l, buf.slice());
    return 1;
}
