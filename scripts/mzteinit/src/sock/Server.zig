const std = @import("std");

const message = @import("message.zig");

const Mutex = @import("../mutex.zig").Mutex;

const log = std.log.scoped(.server);

alloc: std.mem.Allocator,
env: *Mutex(std.process.EnvMap),
ss: std.net.StreamServer,

const Server = @This();

pub fn init(alloc: std.mem.Allocator, sockpath: []const u8, env: *Mutex(std.process.EnvMap)) !Server {
    var ss = std.net.StreamServer.init(.{});
    try ss.listen(try std.net.Address.initUnix(sockpath));
    return .{ .alloc = alloc, .ss = ss, .env = env };
}

pub fn run(self: *Server) !void {
    while (true) {
        const con = try self.ss.accept();
        errdefer con.stream.close();
        (try std.Thread.spawn(.{}, handleConnection, .{ self, con })).detach();
    }
}

pub fn handleConnection(self: *Server, con: std.net.StreamServer.Connection) !void {
    defer con.stream.close();
    while (true) {
        const msg = message.Serverbound.read(con.stream.reader(), self.alloc) catch |e| {
            switch (e) {
                error.EndOfStream => return,
                else => return e,
            }
        };
        defer msg.deinit(self.alloc);

        switch (msg) {
            .ping => {
                log.info("got ping!", .{});
                try (message.Clientbound{ .pong = .{} }).write(con.stream.writer());
            },
            .getenv => |key| {
                self.env.mtx.lock();
                defer self.env.mtx.unlock();

                log.info("env var '{s}' requested", .{key.data});

                const payload = message.Clientbound{ .getenv_res = .{
                    .inner = if (self.env.data.get(key.data)) |v|
                        .{ .data = v }
                    else
                        null,
                } };
                try payload.write(con.stream.writer());
            },
        }
    }
}
