const std = @import("std");
const s2s = @import("s2s");

const message = @import("message.zig");

const Mutex = @import("../mutex.zig").Mutex;

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
    while (true) {
        var msg = s2s.deserializeAlloc(con.stream.reader(), message.Serverbound, self.alloc) catch |e| {
            switch (e) {
                error.EndOfStream => {
                    con.stream.close();
                    return;
                },
                else => return e,
            }
        };
        defer s2s.free(self.alloc, message.Serverbound, &msg);

        switch (msg) {
            .ping => try s2s.serialize(con.stream.writer(), message.Clientbound, .pong),
            .getenv => |key| {
                self.env.mtx.lock();
                defer self.env.mtx.unlock();

                try s2s.serialize(
                    con.stream.writer(),
                    message.Clientbound,
                    .{ .getenv_res = self.env.data.get(key) },
                );
            },
        }
    }
}
