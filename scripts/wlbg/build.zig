const std = @import("std");

const Scanner = @import("wayland").Scanner;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const scanner = Scanner.create(b, .{});
    const wayland_mod = b.createModule(.{ .source_file = scanner.result });

    const exe = b.addExecutable(.{
        .name = "wlbg",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    exe.addModule("wayland", wayland_mod);

    scanner.addSystemProtocol("stable/xdg-shell/xdg-shell.xml");
    scanner.addSystemProtocol("unstable/xdg-output/xdg-output-unstable-v1.xml");
    scanner.addCustomProtocol("wlr-layer-shell-unstable-v1.xml");

    scanner.generate("wl_compositor", 5);
    scanner.generate("wl_shm", 1);
    scanner.generate("zwlr_layer_shell_v1", 4);
    scanner.generate("zxdg_output_manager_v1", 3);
    scanner.generate("xdg_wm_base", 5); // dependency of layer shell
    scanner.generate("wl_seat", 8);
    scanner.generate("wl_output", 4);

    exe.linkLibC();
    exe.linkSystemLibrary("wayland-client");
    exe.linkSystemLibrary("wayland-egl");
    exe.linkSystemLibrary("EGL");
    exe.linkSystemLibrary("GLESv2");
    scanner.addCSource(exe);

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
