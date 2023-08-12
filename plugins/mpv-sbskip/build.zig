const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addSharedLibrary(.{
        .name = "mpv-sbskip",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    lib.linkLibC();

    const install_step = b.addInstallArtifact(lib, .{
        // this is not a standard MPV installation path, but instead one that makes sense.
        // this requires a symlink ../../../.local/share/mpv/scripts => ~/.config/mpv/scripts
        .dest_dir = .{ .override = .{ .custom = "share/mpv/scripts" } },
        .dest_sub_path = "sbskip.so",
    });
    b.getInstallStep().dependOn(&install_step.step);
}
