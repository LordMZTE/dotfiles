const std = @import("std");

const Scanner = @import("wayland").Scanner;

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardOptimizeOption(.{});

    const scanner = Scanner.create(b, .{});
    const wayland_mod = b.createModule(.{ .source_file = scanner.result });

    const exe = b.addExecutable(.{
        .name = "vinput",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = mode,
    });

    exe.addModule("wayland", wayland_mod);

    scanner.addSystemProtocol("stable/xdg-shell/xdg-shell.xml");

    scanner.generate("wl_seat", 4);
    scanner.generate("wl_data_device_manager", 3);
    scanner.generate("wl_compositor", 4);
    scanner.generate("wl_shm", 1);
    scanner.generate("xdg_wm_base", 3);

    exe.linkLibC();
    exe.linkSystemLibrary("wayland-client");

    exe.strip = mode != .Debug;

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
