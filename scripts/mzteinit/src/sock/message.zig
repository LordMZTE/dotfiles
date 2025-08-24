const std = @import("std");

const native_endian = @import("builtin").cpu.arch.endian();

pub const Serverbound = union(enum) {
    ping: NullPayload,
    getenv: BytesPayload,
};

pub const Clientbound = union(enum) {
    pong: NullPayload,
    getenv_res: OptionalPayload(BytesPayload),
};

pub const NullPayload = struct {
    fn read(_:  *std.Io.Reader, _: std.mem.Allocator) !NullPayload {
        return .{};
    }

    fn write(_: NullPayload, _:  *std.Io.Writer) !void {}
};

pub const BytesPayload = struct {
    data: []const u8,

    fn read(reader: *std.Io.Reader, alloc: std.mem.Allocator) !BytesPayload {
        const len = try reader.takeInt(usize, native_endian);
        const data = try alloc.alloc(u8, len);
        errdefer alloc.free(data);
        try reader.readSliceAll(data);

        return .{ .data = data };
    }

    fn write(self: *const BytesPayload, writer:  *std.Io.Writer) !void {
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

        fn read(reader: *std.Io.Reader, alloc: std.mem.Allocator) !Self {
            const present_byte = try reader.takeByte();
            return switch (present_byte) {
                0 => .{ .inner = null },
                1 => .{ .inner = try T.read(reader, alloc) },
                else => error.InvalidPacket,
            };
        }

        fn write(self: *const Self, writer: *std.Io.Writer) !void {
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

pub fn readMessage(comptime T: type, reader: *std.Io.Reader, alloc: std.mem.Allocator) !T {
    const Tag = std.meta.Tag(T);

    switch (std.enums.fromInt(
        Tag,
        try reader.takeInt(EnumIntRoundUp(Tag), native_endian),
    ) orelse return error.InvalidTag) {
        inline else => |t| {
            const Field = @FieldType(T, @tagName(t));
            return @unionInit(T, @tagName(t), try Field.read(reader, alloc));
        },
    }
}

pub fn writeMessage(comptime T: type, msg: T, writer: *std.Io.Writer) !void {
    const Tag = std.meta.Tag(T);

    try writer.writeInt(EnumIntRoundUp(Tag), @intFromEnum(msg), native_endian);
    switch (msg) {
        inline else => |*t| try t.write(writer),
    }
}

pub fn deinitMessage(comptime T: type, msg: T, alloc: std.mem.Allocator) void {
    switch (msg) {
        inline else => |d| if (@hasDecl(@TypeOf(d), "deinit")) d.deinit(alloc),
    }
}
