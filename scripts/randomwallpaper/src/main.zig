const std = @import("std");
const xinerama = @import("xinerama.zig");
const Walker = @import("Walker.zig");
const c = @import("ffi.zig").c;

pub fn main() !u8 {
    const alloc = std.heap.c_allocator;
    const home_s = std.os.getenv("HOME") orelse return error.HomeNotSet;
    const screens = try xinerama.getHeadCount();

    var walker = Walker.init(alloc);
    defer walker.deinit();

    try walker.walk(
        try std.fs.openIterableDirAbsolute(
            "/usr/share/backgrounds/",
            .{},
        ),
    );

    try walkLocalWps(&walker, home_s);

    const feh_baseargs = [_][]const u8{
        "feh",
        "--no-fehbg",
        "--bg-fill",
    };

    var feh_argv = try alloc.alloc(
        []const u8,
        feh_baseargs.len + @intCast(usize, screens),
    );
    defer alloc.free(feh_argv);
    std.mem.copy([]const u8, feh_argv, &feh_baseargs);

    const rand = std.rand.DefaultPrng.init(std.crypto.random.int(u64)).random();

    var i: u31 = 0;
    while (i < screens) : (i += 1) {
        const idx = rand.uintAtMost(usize, walker.files.items.len - 1);
        feh_argv[feh_baseargs.len + i] = walker.files.items[idx];
    }

    std.log.info("feh argv: {s}", .{feh_argv});
    const term = try std.ChildProcess.init(feh_argv, alloc).spawnAndWait();

    const exit = switch (term) {
        .Exited => |n| n,
        .Signal,
        .Stopped,
        .Unknown,
        => |n| b: {
            std.log.err("Child borked with code {}", .{n});
            break :b 1;
        },
    };

    return exit;
}

fn walkLocalWps(walker: *Walker, home_s: []const u8) !void {
    const home = std.fs.cwd().openDir(home_s, .{}) catch return;
    const local_wp = home.openIterableDir(".local/share/backgrounds/", .{}) catch return;
    try walker.walk(local_wp);
}
