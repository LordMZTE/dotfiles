const std = @import("std");
const common = @import("common");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const ansi_term_mod = b.dependency("ansi_term", .{}).module("ansi-term");
    const common_mod = b.dependency("common", .{}).module("common");

    const exe = b.addExecutable(.{
        .name = "mzteinit",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const mzteinitctl = b.addExecutable(.{
        .name = "mzteinitctl",
        .root_source_file = b.path("src/mzteinitctl.zig"),
        .target = target,
        .optimize = optimize,
    });

    inline for (.{ mzteinitctl, exe }) |e| {
        e.root_module.addImport("ansi-term", ansi_term_mod);
        e.root_module.addImport("common", common_mod);
    }

    // TODO: Broken, see: https://github.com/ziglang/zig/issues/20525
    //const cg_opt = try common.confgenGet(struct {
    //    gtk_theme: []const u8,
    //    mzteinit_entries: []const struct {
    //        key: []const u8,
    //        label: []const u8,
    //        cmd: []const []const u8,
    //        quit: bool = false,
    //    },
    //}, b.allocator);

    const cg_opt = try common.confgenGet(struct {
        gtk_theme: []const u8,
    }, b.allocator);

    const opts = b.addOptions();
    opts.addOption(@TypeOf(cg_opt), "cg", cg_opt);
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
