const std = @import("std");

const Client = @import("sock/Client.zig");

pub const std_options = std.Options{
    .log_level = .debug,
    .logFn = @import("common").logFn,
};

pub fn main(init: std.process.Init) !void {
    const alloc = init.gpa;
    const argv = init.minimal.args.vector;

    if (argv.len < 2)
        return error.InvalidArgs;

    const verb = std.mem.span(argv[1]);

    if (std.mem.eql(u8, verb, "ping")) {
        const client = try Client.connect(
            init.io,
            init.environ_map.get("MZTEINIT_SOCKET") orelse return error.SocketPathUnknown,
        );
        defer client.deinit();

        try client.ping(alloc);
    } else if (std.mem.eql(u8, verb, "getenv")) {
        if (argv.len < 3)
            return error.InvalidArgs;

        const client = if (init.environ_map.get("MZTEINIT_SOCKET")) |sockpath|
            try Client.connect(init.io, sockpath)
        else nosock: {
            std.log.warn("MZTEINIT_SOCKET not set", .{});
            break :nosock null;
        };
        defer if (client) |cl| cl.deinit();

        const mzteinit_val = if (client) |cl|
            try cl.getenv(alloc, std.mem.span(argv[2]))
        else
            null;
        defer if (mzteinit_val) |v| alloc.free(v);

        const val = mzteinit_val orelse getenv: {
            std.log.warn("Variable not known to MZTEINIT, falling back to current environment.", .{});
            break :getenv init.environ_map.get(std.mem.span(argv[2]));
        };

        if (val) |v| {
            var write_buf: [512]u8 = undefined;
            var writer = std.Io.File.stdout().writer(init.io, &write_buf);

            try writer.interface.writeAll(v);
            try writer.interface.writeByte('\n');
            try writer.interface.flush();
        }
    }
}
