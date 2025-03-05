const std = @import("std");

const native_endian = @import("builtin").cpu.arch.endian();

pub const Serverbound = union(enum) {
    ping: NullPayload,
    getenv: BytesPayload,

    pub usingnamespace MessageFunctions(Serverbound);
};

pub const Clientbound = union(enum) {
    pong: NullPayload,
    getenv_res: OptionalPayload(BytesPayload),

    pub usingnamespace MessageFunctions(Clientbound);
};

pub const NullPayload = struct {
    fn read(_: anytype, _: std.mem.Allocator) !NullPayload {
        return .{};
    }

    fn write(_: NullPayload, _: anytype) !void {}
};

pub const BytesPayload = struct {
    data: []const u8,

    fn read(reader: anytype, alloc: std.mem.Allocator) !BytesPayload {
        const len = try reader.readInt(usize, native_endian);
        const data = try alloc.alloc(u8, len);
        errdefer alloc.free(data);
        try reader.readNoEof(data);

        return .{ .data = data };
    }

    fn write(self: *const BytesPayload, writer: anytype) !void {
        try writer.writeInt(usize, self.data.len, native_endian);
        try writer.writeAll(self.data);
    }

    fn deinit(self: BytesPayload, alloc: std.mem.Allocator) void {
        alloc.free(self.data);
    }
};

pub fn OptionalPayload(comptime T: type) type {
    return struct {
        inner: ?T,

        const Self = @This();

        fn read(reader: anytype, alloc: std.mem.Allocator) !Self {
            const present_byte = try reader.readByte();
            return switch (present_byte) {
                0 => .{ .inner = null },
                1 => .{ .inner = try T.read(reader, alloc) },
                else => error.InvalidPacket,
            };
        }

        fn write(self: *const Self, writer: anytype) !void {
            if (self.inner) |i| {
                try writer.writeByte(1);
                try i.write(writer);
            } else {
                try writer.writeByte(0);
            }
        }

        fn deinit(self: Self, alloc: std.mem.Allocator) void {
            if (@hasDecl(T, "deinit")) {
                if (self.inner) |i| {
                    i.deinit(alloc);
                }
            }
        }
    };
}

fn EnumIntRoundUp(comptime T: type) type {
    const int_info = @typeInfo(@typeInfo(T).@"enum".tag_type).int;
    return std.meta.Int(int_info.signedness, std.mem.alignForward(u16, int_info.bits, 8));
}

fn MessageFunctions(comptime Self: type) type {
    return struct {
        const Tag = std.meta.Tag(Self);

        pub fn read(reader: anytype, alloc: std.mem.Allocator) !Self {
            switch (try std.meta.intToEnum(
                Tag,
                try reader.readInt(EnumIntRoundUp(Tag), native_endian),
            )) {
                inline else => |t| {
                    const Field = std.meta.FieldType(Self, t);
                    return @unionInit(Self, @tagName(t), try Field.read(reader, alloc));
                },
            }
        }

        pub fn write(self: *const Self, writer: anytype) !void {
            try writer.writeInt(EnumIntRoundUp(Tag), @intFromEnum(self.*), native_endian);
            switch (self.*) {
                inline else => |*t| try t.write(writer),
            }
        }

        pub fn deinit(self: Self, alloc: std.mem.Allocator) void {
            switch (self) {
                inline else => |d| if (@hasDecl(@TypeOf(d), "deinit")) d.deinit(alloc),
            }
        }
    };
}
