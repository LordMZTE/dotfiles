const std = @import("std");
const common = @import("common");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const common_dep = b.dependency("common", .{ .target = target, .optimize = optimize });
    const common_mod = common_dep.module("common");

    const mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "common", .module = common_mod },
        },
    });
    mod.addAnonymousImport("cg", .{
        .root_source_file = common.confgenPath(b, "cgassets/constsiz_opts.zon"),
    });
    mod.addAnonymousImport("cgopts", .{
        .root_source_file = common.confgenPath(b, "cgassets/mzteriver-opts.zon"),
    });

    const exe = b.addExecutable(.{
        .name = "mzteriver",
        .root_module = mod,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    run_cmd.addPassthruArgs();

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
