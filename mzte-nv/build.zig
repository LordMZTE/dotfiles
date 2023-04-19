const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
    const target = b.standardTargetOptions(.{});

    if (target.os_tag orelse @import("builtin").os.tag == .windows)
        // windows is an error in many ways
        return error.Windows;

    const mode = b.standardOptimizeOption(.{});

    const lib = b.addSharedLibrary(.{
        .name = "mzte-nv",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = mode,
    });

    lib.linkLibC();
    lib.linkSystemLibrary("luajit");

    lib.strip = mode != .Debug;
    lib.unwind_tables = true;

    b.getInstallStep().dependOn(&b.addInstallFile(lib.getOutputSource(), "share/nvim/mzte-nv.so").step);

    // this is the install step for the lua config compiler binary
    const compiler = b.addExecutable(.{
        .name = "mzte-nv-compile",
        .root_source_file = .{ .path = "src/compiler.zig" },
        .target = target,
        .optimize = mode,
    });

    compiler.linkLibC();
    compiler.linkSystemLibrary("luajit");

    compiler.strip = mode != .Debug;
    compiler.unwind_tables = true;

    b.installArtifact(lib);
}
