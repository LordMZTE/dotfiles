const std = @import("std");

const Client = @import("sock/Client.zig");

pub const std_options = std.Options{
    .log_level = .debug,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    if (std.os.argv.len < 2)
        return error.InvalidArgs;

    const verb = std.mem.span(std.os.argv[1]);

    if (std.mem.eql(u8, verb, "ping")) {
        const client = try Client.connect(
            std.os.getenv("MZTEINIT_SOCKET") orelse return error.SocketPathUnknown,
        );
        defer client.deinit();

        try client.ping(alloc);
    } else if (std.mem.eql(u8, verb, "getenv")) {
        if (std.os.argv.len < 3)
            return error.InvalidArgs;

        const client = if (std.os.getenv("MZTEINIT_SOCKET")) |sockpath|
            try Client.connect(sockpath)
        else nosock: {
            std.log.warn("MZTEINIT_SOCKET not set", .{});
            break :nosock null;
        };
        defer if (client) |cl| cl.deinit();

        const mzteinit_val = if (client) |cl|
            try cl.getenv(alloc, std.mem.span(std.os.argv[2]))
        else
            null;
        defer if (mzteinit_val) |v| alloc.free(v);

        const val = mzteinit_val orelse getenv: {
            std.log.warn("Variable not known to MZTEINIT, falling back to current environment.", .{});
            break :getenv std.os.getenv(std.mem.span(std.os.argv[2]));
        };

        if (val) |v| {
            try std.io.getStdOut().writer().print("{s}\n", .{v});
        }
    }
}
