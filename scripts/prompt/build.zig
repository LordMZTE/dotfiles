const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "prompt",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = mode,
    });

    exe.linkLibC();
    exe.linkSystemLibrary("libgit2");

    exe.root_module.addImport("common", b.dependency("common", .{}).module("common"));
    exe.root_module.addImport("ansi-term", b.dependency("ansi_term", .{}).module("ansi_term"));
    exe.root_module.addImport("known-folders", b.dependency("known_folders", .{}).module("known-folders"));

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
