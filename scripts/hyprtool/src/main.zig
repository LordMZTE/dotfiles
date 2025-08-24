const std = @import("std");

pub const std_options = std.Options{
    .logFn = @import("common").logFn,
};

pub fn main() !void {
    if (std.os.argv.len != 2 or !std.mem.eql(u8, std.mem.span(std.os.argv[1]), "fullerscreen"))
        return error.InvalidArgs;

    const inst_sig = std.posix.getenv("HYPRLAND_INSTANCE_SIGNATURE") orelse
        return error.MissingInstanceSignature;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const socket_path = try std.fs.path.join(alloc, &.{ "/tmp", "hypr", inst_sig, ".socket.sock" });
    defer alloc.free(socket_path);

    try @import("fullerscreen.zig").doFullerscreen(alloc, socket_path);
}
