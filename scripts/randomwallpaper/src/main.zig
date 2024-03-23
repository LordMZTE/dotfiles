const std = @import("std");
const xinerama = @import("xinerama.zig");
const Walker = @import("Walker.zig");

pub const std_options = std.Options{
    .log_level = .debug,
    .logFn = @import("common").logFn,
};

pub fn main() !u8 {
    const alloc = std.heap.c_allocator;
    const home_s = std.posix.getenv("HOME") orelse return error.HomeNotSet;
    const runtime_dir = std.posix.getenv("XDG_RUNTIME_DIR") orelse return error.MissingRuntimeDir;

    var walker = Walker.init(alloc);
    defer walker.deinit();

    try walker.walk(
        try std.fs.openDirAbsolute(
            "/usr/share/backgrounds/",
            .{ .iterate = true },
        ),
    );

    try walkLocalWps(&walker, home_s);

    const swww_socket_path = try std.fs.path.join(alloc, &.{ runtime_dir, "swww.socket" });
    defer alloc.free(swww_socket_path);

    const has_swww = if (std.fs.cwd().statFile(swww_socket_path)) |_| true else |e| switch (e) {
        error.FileNotFound => false,
        else => return e,
    };

    if (has_swww) {
        std.log.info("found running swww daemon, using swww backend", .{});
        return try setWallpapersSwww(alloc, walker.files.items);
    } else {
        std.log.info("using X/feh backend", .{});
        return try setWallpapersX(alloc, walker.files.items);
    }
}

fn walkLocalWps(walker: *Walker, home_s: []const u8) !void {
    const wp_path = try std.fs.path.join(walker.files.allocator, &.{ home_s, ".local/share/backgrounds" });
    defer walker.files.allocator.free(wp_path);

    var local_wp = std.fs.cwd().openDir(wp_path, .{ .iterate = true }) catch |e| switch (e) {
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

fn setWallpapersSwww(alloc: std.mem.Allocator, wps: []const []const u8) !u8 {
    const exec_res = try std.process.Child.run(.{
        .allocator = alloc,
        .argv = &.{ "swww", "query" },
    });
    defer alloc.free(exec_res.stdout);
    defer alloc.free(exec_res.stderr);

    if (!std.meta.eql(exec_res.term, .{ .Exited = 0 }))
        return error.SwwwQuery;

    var prng = std.rand.DefaultPrng.init(std.crypto.random.int(u64));
    const rand = prng.random();

    var output_iter = std.mem.tokenizeScalar(u8, exec_res.stdout, '\n');
    while (output_iter.next()) |line| {
        if (line.len == 0) continue;
        const output = std.mem.sliceTo(line, ':');

        const argv = [_][]const u8{
            "swww",
            "img",
            wps[rand.uintAtMost(usize, wps.len - 1)],
            "--outputs",
            output,
            "--transition-type",
            "wipe",
            "--transition-angle",
            "30",
            "--transition-bezier",
            "0.8,0.0,0.2,1.0",
            "--transition-fps",
            "60",
            "--transition-duration",
            "2",
        };

        var child = std.process.Child.init(&argv, alloc);
        const term = try child.spawnAndWait();
        const code = switch (term) {
            .Exited => |n| n,
            .Signal,
            .Stopped,
            .Unknown,
            => |n| b: {
                std.log.err("Child borked with code {}", .{n});
                break :b 1;
            },
        };

        if (code != 0) return code;
    }

    return 0;
}

fn setWallpapersX(alloc: std.mem.Allocator, wps: []const []const u8) !u8 {
    const screens = try xinerama.getHeadCount();

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
    @memcpy(feh_argv[0..feh_baseargs.len], &feh_baseargs);

    var prng = std.rand.DefaultPrng.init(std.crypto.random.int(u64));
    const rand = prng.random();

    var i: u31 = 0;
    while (i < screens) : (i += 1) {
        const idx = rand.uintAtMost(usize, wps.len - 1);
        feh_argv[feh_baseargs.len + i] = wps[idx];
    }

    std.log.info("feh argv: {s}", .{feh_argv});
    var child = std.process.Child.init(feh_argv, alloc);
    const term = try child.spawnAndWait();

    return switch (term) {
        .Exited => |n| n,
        .Signal,
        .Stopped,
        .Unknown,
        => |n| b: {
            std.log.err("Child borked with code {}", .{n});
            break :b 1;
        },
    };
}
