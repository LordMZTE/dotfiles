const std = @import("std");

const Client = @import("sock/Client.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    if (std.os.argv.len < 2)
        return error.InvalidArgs;

    const verb = std.mem.span(std.os.argv[1]);

    const client = try Client.connect(
        std.os.getenv("MZTEINIT_SOCKET") orelse return error.SocketPathUnknown,
    );
    defer client.deinit();

    if (std.mem.eql(u8, verb, "ping")) {
        try client.ping(alloc);
    } else if (std.mem.eql(u8, verb, "getenv")) {
        if (std.os.argv.len < 3)
            return error.InvalidArgs;

        const val = try client.getenv(alloc, std.mem.span(std.os.argv[2]));
        defer if (val) |v| alloc.free(v);

        if (val) |v| {
            try std.io.getStdOut().writer().print("{s}\n", .{v});
        }
    }
}
