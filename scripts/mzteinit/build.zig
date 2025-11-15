const std = @import("std");
const common = @import("common");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const ansi_term_mod = b.dependency("ansi_term", .{}).module("ansi_term");
    const common_mod = b.dependency("common", .{
        .target = target,
        .optimize = optimize,
    }).module("common");

    const mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "mzteinit",
        .root_module = mod,
    });

    const mzteinitctl_mod = b.createModule(.{
        .root_source_file = b.path("src/mzteinitctl.zig"),
        .target = target,
        .optimize = optimize,
    });

    const mzteinitctl = b.addExecutable(.{
        .name = "mzteinitctl",
        .root_module = mzteinitctl_mod,
    });

    inline for (.{ mzteinitctl_mod, mod }) |m| {
        m.addImport("ansi-term", ansi_term_mod);
        m.addImport("common", common_mod);
    }

    mod.addAnonymousImport("cg", .{
        .root_source_file = common.confgenPath(b, "cgassets/constsiz_opts.zon"),
    });

    b.installArtifact(exe);
    b.installArtifact(mzteinitctl);

    const run_mzteinitctl = b.addRunArtifact(mzteinitctl);
    run_mzteinitctl.step.dependOn(b.getInstallStep());

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_mzteinitctl.addArgs(args);
        run_cmd.addArgs(args);
    }

    const run_mzteinitctl_step = b.step("run-mzteinitctl", "Run mzteinitctl");
    run_mzteinitctl_step.dependOn(&run_mzteinitctl.step);

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
