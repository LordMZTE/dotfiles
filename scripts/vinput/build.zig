const std = @import("std");

const Scanner = @import("wayland").Scanner;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardOptimizeOption(.{});

    const scanner = Scanner.create(b, .{});
    const wayland_mod = b.createModule(.{ .root_source_file = scanner.result });

    const mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = mode,
        .link_libc = true,
    });

    const exe = b.addExecutable(.{
        .name = "vinput",
        .root_module = mod,
    });

    mod.addImport("common", b.dependency("common", .{}).module("common"));
    mod.addImport("wayland", wayland_mod);

    scanner.addSystemProtocol("stable/xdg-shell/xdg-shell.xml");

    scanner.generate("wl_seat", 4);
    scanner.generate("wl_data_device_manager", 3);
    scanner.generate("wl_compositor", 4);
    scanner.generate("wl_shm", 1);
    scanner.generate("xdg_wm_base", 2);

    mod.linkSystemLibrary("wayland-client", .{});

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
