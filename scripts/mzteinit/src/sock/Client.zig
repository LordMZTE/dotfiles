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
    try (message.Serverbound{ .ping = .{} }).write(self.stream.writer());
    const res = try message.Clientbound.read(self.stream.reader(), alloc);
    defer res.deinit(alloc);
    if (!std.meta.eql(res, .{ .pong = .{} }))
        return error.InvalidResponse;
}

pub fn getenv(self: Client, alloc: std.mem.Allocator, key: []const u8) !?[]u8 {
    try (message.Serverbound{ .getenv = .{ .data = key } }).write(self.stream.writer());
    const res = try message.Clientbound.read(self.stream.reader(), alloc);
    defer res.deinit(alloc);
    return switch (res) {
        .getenv_res => |val| if (val.inner) |v| try alloc.dupe(u8, v.data) else null,
        else => error.InvalidResponse,
    };
}
