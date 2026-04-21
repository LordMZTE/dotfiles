const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardOptimizeOption(.{});

    const translate_c = b.addTranslateC(.{
        .root_source_file = b.path("c.h"),
        .target = target,
        .optimize = mode,
    });

    translate_c.linkSystemLibrary("libgit2", .{});

    const mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = mode,
        .imports = &.{
            .{ .name = "c", .module = translate_c.createModule() },
        },
    });

    const exe = b.addExecutable(.{
        .name = "prompt",
        .root_module = mod,
    });

    mod.addImport("common", b.dependency("common", .{
        .target = target,
        .optimize = mode,
    }).module("common"));
    mod.addImport("ansi-term", b.dependency("ansi_term", .{}).module("ansi_term"));

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
