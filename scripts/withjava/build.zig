const std = @import("std");
const common = @import("common");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "withjava",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const cgopt = try common.confgenGet(struct {
        nix: struct {
            jvm: ?[:0]const u8 = null,
        },
    }, b.allocator);

    const opts = b.addOptions();
    opts.addOption(?[:0]const u8, "jvm", cgopt.nix.jvm);

    exe.root_module.addImport("common", b.dependency("common", .{}).module("common"));
    exe.root_module.addImport("opts", opts.createModule());

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
