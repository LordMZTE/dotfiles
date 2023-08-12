const std = @import("std");
const xinerama = @import("xinerama.zig");
const Walker = @import("Walker.zig");

pub const std_options = struct {
    pub const log_level = .debug;
};

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
        feh_baseargs.len + @as(usize, @intCast(screens)),
    );
    defer alloc.free(feh_argv);
    std.mem.copy([]const u8, feh_argv, &feh_baseargs);

    var prng = std.rand.DefaultPrng.init(std.crypto.random.int(u64));
    const rand = prng.random();

    var i: u31 = 0;
    while (i < screens) : (i += 1) {
        const idx = rand.uintAtMost(usize, walker.files.items.len - 1);
        feh_argv[feh_baseargs.len + i] = walker.files.items[idx];
    }

    std.log.info("feh argv: {s}", .{feh_argv});
    var child = std.ChildProcess.init(feh_argv, alloc);
    const term = try child.spawnAndWait();

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
    const wp_path = try std.fs.path.join(walker.files.allocator, &.{ home_s, ".local/share/backgrounds" });
    defer walker.files.allocator.free(wp_path);

    var local_wp = std.fs.cwd().openIterableDir(wp_path, .{}) catch |e| switch (e) {
        error.FileNotFound => {
            std.log.warn(
                "No local wallpaper directory @ {s}, skipping local wallpapers",
                .{wp_path},
            );
            return;
        },
        else => return e,
    };
    defer local_wp.close();

    try walker.walk(local_wp);
}
