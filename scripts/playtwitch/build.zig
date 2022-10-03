const std = @import("std");
const pkgs = @import("deps.zig").pkgs;

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("playtwitch", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);

    exe.linkLibC();
    exe.linkSystemLibrary("gtk4");
    pkgs.addAllTo(exe);

    exe.strip = mode != .Debug;

    exe.install();

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

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
