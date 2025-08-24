const std = @import("std");

const message = @import("message.zig");

stream: std.net.Stream,

const Client = @This();

pub fn connect(addr: []const u8) !Client {
    const stream = try std.net.connectUnixSocket(addr);
    return .{ .stream = stream };
}

pub fn deinit(self: Client) void {
    self.stream.close();
}

pub fn ping(self: Client, alloc: std.mem.Allocator) !void {
    var write_buf: [8]u8 = undefined;
    var read_buf: [8]u8 = undefined;

    var writer = self.stream.writer(&write_buf);
    var reader = self.stream.reader(&read_buf);

    try message.writeMessage(message.Serverbound, .ping, &writer.interface);
    try writer.interface.flush();

    const res = try message.readMessage(message.Clientbound, reader.interface(), alloc);
    defer message.deinitMessage(message.Clientbound, res, alloc);

    if (!std.meta.eql(res, .{ .pong = .{} }))
        return error.InvalidResponse;
}

pub fn getenv(self: Client, alloc: std.mem.Allocator, key: []const u8) !?[]u8 {
    var write_buf: [512]u8 = undefined;
    var read_buf: [512]u8 = undefined;

    var writer = self.stream.writer(&write_buf);
    var reader = self.stream.reader(&read_buf);

    try message.writeMessage(message.Serverbound, .{ .getenv = .{ .data = key } }, &writer.interface);
    try writer.interface.flush();

    const res = try message.readMessage(message.Clientbound, reader.interface(), alloc);
    defer message.deinitMessage(message.Clientbound, res, alloc);

    return switch (res) {
        .getenv_res => |val| if (val.inner) |v| try alloc.dupe(u8, v.data) else null,
        else => error.InvalidResponse,
    };
}
