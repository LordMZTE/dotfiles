const std = @import("std");
const c = @import("ffi.zig").c;

pub fn luaPushAny(l: *c.lua_State, x: anytype) void {
    const T = @TypeOf(x);

    switch (@typeInfo(T)) {
        .Void, .Null => c.lua_pushnil(l),
        .Bool => c.lua_pushboolean(l, @intCast(c_int, @boolToInt(x))),
        .Int, .ComptimeInt => c.lua_pushinteger(l, @intCast(c_int, x)),
        .Float, .ComptimeFloat => c.lua_pushnumber(l, @floatCast(c.lua_Number, x)),
        .Pointer => |P| {
            switch (P.size) {
                .One => {
                    if (T == c.lua_CFunction or
                        T == @typeInfo(c.lua_CFunction).Optional.child)
                        c.lua_pushcfunction(l, x)
                    else
                        luaPushAny(l, x.*);
                },
                .Slice => {
                    if (P.child == u8) {
                        if (P.sentinel == null)
                            @compileError("luaPushAny doesn't support " ++ @typeName(T));

                        c.lua_pushstring(l, x.ptr);
                    } else {
                        c.lua_createtable(l, x.len, 0);

                        for (x) |element, i| {
                            luaPushAny(l, element);
                            c.lua_rawseti(l, -2, i + 1);
                        }
                    }
                },
                .C => {
                    if (P.child != u8)
                        @compileError("luaPushAny doesn't support " ++ @typeName(T));

                    c.lua_pushstring(l, x);
                },
                .Many => {
                    if (P.child != u8)
                        @compileError("luaPushAny doesn't support " ++ @typeName(T));

                    c.lua_pushstring(l, x);
                },
            }
        },
        .Array => luaPushAny(l, &x),
        .Struct => |S| {
            if (comptime std.meta.trait.hasFn("luaPush")(T)) {
                return x.luaPush(l);
            }

            if (S.is_tuple) {
                c.lua_createtable(l, S.fields.len, 0);

                inline for (S.fields) |Field, i| {
                    luaPushAny(l, @field(x, Field.name));
                    c.lua_rawseti(l, -2, i + 1);
                }
            } else {
                c.lua_createtable(l, 0, S.fields.len);

                inline for (S.fields) |Field| {
                    luaPushAny(l, @field(x, Field.name));
                    c.lua_setfield(l, -2, Field.name.ptr);
                }
            }
        },
        .Optional => {
            if (x) |val| {
                luaPushAny(l, val);
            } else {
                c.lua_pushnil(l);
            }
        },
        .Enum, .EnumLiteral => c.lua_pushstring(l, @tagName(x)),
        .Type => {
            if (@hasDecl(x, "luaPush")) {
                return x.luaPush(l);
            }
            @compileError("luaPushAny doesn't support " ++ @typeName(T));
        },
        else => @compileError("luaPushAny doesn't support " ++ @typeName(T)),
    }
}
