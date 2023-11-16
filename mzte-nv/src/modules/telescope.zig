//! Module for telescope.nvim.
const std = @import("std");
const ser = @import("../ser.zig");
const ffi = @import("../ffi.zig");
const c = ffi.c;

pub fn luaPush(l: *c.lua_State) void {
    ser.luaPushAny(l, .{
        .makePathTransformer = ffi.luaFunc(lMakePathTransformer),
    });
}

fn lMakePathTransformer(l: *c.lua_State) !c_int {
    c.luaL_checktype(l, 1, c.LUA_TFUNCTION);

    c.lua_pushvalue(l, 1);
    c.lua_pushcclosure(l, ffi.luaFunc(lPathTransformerClosure), 1);
    return 1;
}

fn lPathTransformerClosure(l: *c.lua_State) !c_int {
    c.luaL_checkany(l, 1);
    const path = ffi.luaCheckstring(l, 2);

    // push the delegate function
    c.lua_pushvalue(l, c.lua_upvalueindex(1));
    // push the opts parameter
    c.lua_pushvalue(l, 1);

    const prefix = "jdt://contents/";
    if (std.mem.startsWith(u8, path, prefix)) {
        var buf: [1024 * 4]u8 = undefined;
        var fbs = std.io.fixedBufferStream(&buf);
        if (transformJdtlsURI(path, fbs.writer())) {
            ffi.luaPushString(l, fbs.getWritten());
        } else |e| {
            std.log.err("transforming JDTLS URI: {}", .{e});
            ffi.luaPushString(l, path);
        }
    } else {
        ffi.luaPushString(l, path);
    }

    c.lua_call(l, 2, 1);
    return 1;
}

fn transformJdtlsURI(uri_str: []const u8, writer: anytype) !void {
    // We do a full-on URI parse here because JDTLS often appends parameters and other garbage data.
    const uri = try std.Uri.parse(uri_str);
    var fname_iter = std.fs.path.ComponentIterator(.posix, u8).init(uri.path) catch
        unreachable; // this can only error on windows lol

    _ = fname_iter.next() orelse return error.InvalidPath; // name of the JAR

    const package = (fname_iter.next() orelse return error.InvalidPath).name;
    const classfile = (fname_iter.next() orelse return error.InvalidPath).name;

    if (std.mem.endsWith(u8, classfile, ".class")) {
        try writer.writeAll(classfile[0 .. classfile.len - ".class".len]);
    } else {
        try writer.writeAll(classfile);
    }

    try writer.print(" ({s})", .{package});
}
