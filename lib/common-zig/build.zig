const std = @import("std");

pub const confgen_json_opt = std.json.ParseOptions{ .ignore_unknown_fields = true };

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("common", .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lualib = b.addModule("lualib", .{
        .root_source_file = b.path("lualib/main.zig"),
        .link_libc = true,
        .target = target,
        .optimize = optimize,
    });

    lualib.linkSystemLibrary("luajit", .{});
}

pub fn confgenPath(b: *std.Build, subpath: []const u8) std.Build.LazyPath {
    const path = std.fs.path.join(b.allocator, &.{
        std.posix.getenv("HOME") orelse @panic("HOME not set"),
        "confgenfs",
        subpath,
    }) catch @panic("OOM");

    return .{ .cwd_relative = path };
}

pub fn findRepoRoot(alloc: std.mem.Allocator) ![:0]const u8 {
    if (std.fs.cwd().access(".git", .{})) |_|
        return try alloc.dupeZ(u8, ".")
    else |err| if (err != error.FileNotFound) return err;

    var buf: [std.fs.max_path_bytes]u8 = undefined;
    var i: usize = 0;

    // set 8 as an upper bound to directory depth
    for (0..8) |_| {
        @memcpy(buf[i..][0..3], "../");
        i += 3;
        const path_with_git = try std.fs.path.joinZ(alloc, &.{ buf[0..i], ".git" });
        defer alloc.free(path_with_git);

        if (std.fs.cwd().accessZ(path_with_git, .{})) |_|
            return try alloc.dupeZ(u8, buf[0..i])
        else |err| if (err != error.FileNotFound) return err;
    }

    return error.FileNotFound;
}
