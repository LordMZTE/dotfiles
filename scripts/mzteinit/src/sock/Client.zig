const std = @import("std");
const s2s = @import("s2s");

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
    try s2s.serialize(self.stream.writer(), message.Serverbound, .ping);
    var msg = try s2s.deserializeAlloc(self.stream.reader(), message.Clientbound, alloc);
    defer s2s.free(alloc, message.Clientbound, &msg);
    if (msg != .pong)
        return error.InvalidResponse;
}

pub fn getenv(self: Client, alloc: std.mem.Allocator, key: []const u8) !?[]u8 {
    try s2s.serialize(self.stream.writer(), message.Serverbound, .{ .getenv = key });
    var msg = try s2s.deserializeAlloc(self.stream.reader(), message.Clientbound, alloc);
    defer s2s.free(alloc, message.Clientbound, &msg);
    return switch (msg) {
        .getenv_res => |val| if (val) |v| try alloc.dupe(u8, v) else null,
        else => error.InvalidResponse,
    };
}
