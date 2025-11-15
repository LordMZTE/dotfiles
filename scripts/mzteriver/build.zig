const std = @import("std");
const common = @import("common");

const Scanner = @import("wayland").Scanner;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const scanner = Scanner.create(b, .{});

    const mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const exe = b.addExecutable(.{
        .name = "mzteriver",
        .root_module = mod,
    });

    mod.addAnonymousImport("cg", .{
        .root_source_file = common.confgenPath(b, "cgassets/constsiz_opts.zon"),
    });
    mod.addAnonymousImport("cgopts", .{
        .root_source_file = common.confgenPath(b, "cgassets/mzteriver-opts.zon"),
    });
    mod.addImport("common", b.dependency("common", .{
        .target = target,
        .optimize = optimize,
    }).module("common"));
    mod.addImport("wayland", b.createModule(.{ .root_source_file = scanner.result }));

    scanner.addCustomProtocol(b.path("river-control-unstable-v1.xml"));

    scanner.generate("zriver_control_v1", 1);
    scanner.generate("wl_seat", 7);

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
