const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    //const exe = b.addExecutable("playtwitch", "src/main.zig");
    const exe = b.addExecutable(.{
        .name = "playtwitch",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    exe.linkLibC();
    exe.linkSystemLibrary("cimgui");
    exe.linkSystemLibrary("glfw3");
    exe.linkSystemLibrary("glew");
    exe.linkSystemLibrary("curl");

    exe.strip = optimize != .Debug and optimize != .ReleaseSafe;

    b.installArtifact(exe);

    var logo_install_step = b.addInstallFile(
        .{ .path = "assets/playtwitch.svg" },
        "share/icons/hicolor/scalable/apps/playtwitch.svg",
    );
    b.getInstallStep().dependOn(&logo_install_step.step);

    var desktop_entry_install_step = b.addInstallFile(
        .{ .path = "assets/playtwitch.desktop" },
        "share/applications/playtwitch.desktop",
    );
    b.getInstallStep().dependOn(&desktop_entry_install_step.step);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
