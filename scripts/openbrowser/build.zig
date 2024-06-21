const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "openbrowser",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = mode,
    });
    
    exe.root_module.addImport("common", b.dependency("common", .{}).module("common"));

    b.installArtifact(exe);

    const desktop_install_step = b.addInstallFile(
        b.path("assets/openbrowser.desktop"),
        "share/applications/openbrowser.desktop",
    );
    b.getInstallStep().dependOn(&desktop_install_step.step);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
