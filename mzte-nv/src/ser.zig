const std = @import("std");
const ffi = @import("ffi.zig");
const c = ffi.c;

pub fn luaPushAny(l: *c.lua_State, x: anytype) void {
    const T = @TypeOf(x);

    switch (@typeInfo(T)) {
        .void, .null => c.lua_pushnil(l),
        .bool => c.lua_pushboolean(l, @intCast(@intFromBool(x))),
        .int, .comptime_int => c.lua_pushinteger(l, @intCast(x)),
        .float, .comptime_float => c.lua_pushnumber(l, @floatCast(x)),
        .pointer => |P| {
            switch (P.size) {
                .one => {
                    if (T == c.lua_CFunction or
                        T == @typeInfo(c.lua_CFunction).optional.child)
                    {
                        c.lua_pushcfunction(l, x);
                    } else if (@typeInfo(P.child) == .array) {
                        luaPushAny(l, @as([]const std.meta.Elem(P.child), x));
                    } else {
                        luaPushAny(l, x.*);
                    }
                },
                .slice => {
                    if (P.child == u8) {
                        ffi.luaPushString(l, x);
                    } else {
                        c.lua_createtable(l, @intCast(x.len), 0);

                        for (x, 1..) |element, i| {
                            luaPushAny(l, element);
                            c.lua_rawseti(l, -2, @intCast(i));
                        }
                    }
                },
                .c => {
                    if (P.child != u8)
                        @compileError("luaPushAny doesn't support " ++ @typeName(T));

                    c.lua_pushstring(l, x);
                },
                .many => {
                    if (P.child != u8)
                        @compileError("luaPushAny doesn't support " ++ @typeName(T));

                    c.lua_pushstring(l, x);
                },
            }
        },
        .array => luaPushAny(l, &x),
        .@"struct" => |S| {
            if (comptime std.meta.hasFn(T, "luaPush")) {
                return x.luaPush(l);
            }

            if (S.is_tuple) {
                c.lua_createtable(l, S.fields.len, 0);

                inline for (S.fields, 1..) |Field, i| {
                    luaPushAny(l, @field(x, Field.name));
                    c.lua_rawseti(l, -2, i);
                }
            } else {
                c.lua_createtable(l, 0, S.fields.len);

                inline for (S.fields) |Field| {
                    luaPushAny(l, @field(x, Field.name));
                    c.lua_setfield(l, -2, (Field.name ++ &[_]u8{0}).ptr);
                }
            }
        },
        .optional => {
            if (x) |val| {
                luaPushAny(l, val);
            } else {
                c.lua_pushnil(l);
            }
        },
        .@"enum", .enum_literal => c.lua_pushstring(l, @tagName(x)),
        .type => {
            if (@hasDecl(x, "luaPush")) {
                return x.luaPush(l);
            }
            @compileError("luaPushAny doesn't support " ++ @typeName(T));
        },
        else => @compileError("luaPushAny doesn't support " ++ @typeName(T)),
    }
}
