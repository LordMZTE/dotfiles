const std = @import("std");

const message = @import("message.zig");

const Mutex = @import("../mutex.zig").Mutex;

const log = std.log.scoped(.server);

alloc: std.mem.Allocator,
io: std.Io,
env: *Mutex(*std.process.Environ.Map),
ss: std.Io.net.Server,

const Server = @This();

pub fn init(
    alloc: std.mem.Allocator,
    io: std.Io,
    sockpath: []const u8,
    env: *Mutex(*std.process.Environ.Map),
) !Server {
    return .{
        .alloc = alloc,
        .io = io,
        .ss = try (try std.Io.net.UnixAddress.init(sockpath)).listen(io, .{}),
        .env = env,
    };
}

pub const RunError = std.Io.net.Server.AcceptError || std.Io.ConcurrentError;

pub fn run(self: *Server) RunError!void {
    var congrp: std.Io.Group = .init;
    defer congrp.cancel(self.io);

    while (true) {
        const con = try self.ss.accept(self.io);
        errdefer con.close(self.io);
        try congrp.concurrent(self.io, tryHandleConnection, .{ self, con });
    }
}

pub fn tryHandleConnection(self: *Server, con: std.Io.net.Stream) std.Io.Cancelable!void {
    handleConnection(self, con) catch |e| switch (e) {
        error.Canceled => return error.Canceled,
        else => log.warn("in connection handler: {}", .{e}),
    };
}

pub fn handleConnection(self: *Server, con: std.Io.net.Stream) !void {
    defer con.close(self.io);

    var write_buf: [512]u8 = undefined;
    var read_buf: [512]u8 = undefined;

    var writer = con.writer(self.io, &write_buf);
    var reader = con.reader(self.io, &read_buf);

    while (true) {
        const msg = message.readMessage(message.Serverbound, &reader.interface, self.alloc) catch |e| {
            switch (e) {
                error.EndOfStream => return,
                else => return e,
            }
        };
        defer message.deinitMessage(message.Serverbound, msg, self.alloc);

        switch (msg) {
            .ping => {
                log.info("got ping!", .{});
                try message.writeMessage(message.Clientbound, .pong, &writer.interface);
            },
            .getenv => |key| {
                try self.env.mtx.lock(self.io);
                defer self.env.mtx.unlock(self.io);

                log.info("env var '{s}' requested", .{key.data});

                const payload = message.Clientbound{ .getenv_res = .{
                    .inner = if (self.env.data.get(key.data)) |v|
                        .{ .data = v }
                    else
                        null,
                } };

                try message.writeMessage(message.Clientbound, payload, &writer.interface);
            },
        }

        try writer.interface.flush();
    }
}
