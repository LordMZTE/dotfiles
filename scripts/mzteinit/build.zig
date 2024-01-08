const std = @import("std");
const common = @import("build_common.zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const ansi_term_mod = b.dependency("ansi_term", .{}).module("ansi-term");

    const exe = b.addExecutable(.{
        .name = "mzteinit",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const mzteinitctl = b.addExecutable(.{
        .name = "mzteinitctl",
        .root_source_file = .{ .path = "src/mzteinitctl.zig" },
        .target = target,
        .optimize = optimize,
    });

    inline for (.{ mzteinitctl, exe }) |e| {
        e.root_module.addImport("ansi-term", ansi_term_mod);
    }

    const cg_opt = try common.confgenGet(struct {
        gtk_theme: []u8, // TODO: this being non-const is a workaround for an std bug
    }, "../..", b.allocator);

    const opts = b.addOptions();
    opts.addOption([]const u8, "gtk_theme", cg_opt.gtk_theme);
    exe.root_module.addImport("opts", opts.createModule());

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
