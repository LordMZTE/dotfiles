const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const translate_c = b.addTranslateC(.{
        .root_source_file = b.path("c.h"),
        .target = target,
        .optimize = optimize,
    });

    translate_c.linkSystemLibrary("ddcutil", .{});

    const mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{ .{
            .name = "common",
            .module = b.dependency("common", .{
                .target = target,
                .optimize = optimize,
            }).module("common"),
        }, .{
            .name = "args",
            .module = b.dependency("args", .{
                .target = target,
                .optimize = optimize,
            }).module("args"),
        }, .{
            .name = "c",
            .module = translate_c.createModule(),
        } },
        .link_libc = true,
    });

    const exe = b.addExecutable(.{
        .root_module = mod,
        .name = "brightness",
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
