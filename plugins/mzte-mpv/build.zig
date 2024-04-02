const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addSharedLibrary(.{
        .name = "mzte-mpv",
        .root_source_file = .{ .path = "src/main.zig" },
        .link_libc = true,
        .target = target,
        .optimize = optimize,
    });
    lib.root_module.addImport("common", b.dependency("common", .{}).module("common"));

    // Linking MPV for a plugin is usually undesirable, but it seems to work anyways.
    // This is here because Zig will otherwise not find the necessary header files on NixOS,
    // and there appears to be no way to obtain an include path using pkg-config without
    // also linking.
    lib.root_module.linkSystemLibrary("mpv", .{});

    const install_step = b.addInstallArtifact(lib, .{
        // this is not a standard MPV installation path, but instead one that makes sense.
        // this requires a symlink ../../../.local/share/mpv/scripts => ~/.config/mpv/scripts
        .dest_dir = .{ .override = .{ .custom = "share/mpv/scripts" } },
        .dest_sub_path = "mzte-mpv.so",
    });
    b.getInstallStep().dependOn(&install_step.step);
}
