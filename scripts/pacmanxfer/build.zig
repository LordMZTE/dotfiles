//! This is a tool which wraps rsync and curl and is intended to be used by pacman for downloading
//! packages.
//!
//! pacman.conf:
//! [common]
//! XferCommand = /path/to/pacmanxfer %u %o
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const ansiterm_dep = b.dependency("ansi_term", .{ .target = target, .optimize = optimize });

    const exe = b.addExecutable(.{
        .name = "pacmanxfer",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    exe.addModule("ansi-term", ansiterm_dep.module("ansi-term"));

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
