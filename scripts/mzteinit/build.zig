const std = @import("std");
const common = @import("build_common.zig");

pub fn build(b: *std.build.Builder) !void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "mzteinit",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = mode,
    });

    exe.strip = mode != .Debug;

    exe.addModule("ansi-term", b.dependency("ansi_term", .{}).module("ansi-term"));

    const cg_opt = try common.confgenGet(struct {
        gtk_theme: []const u8,
    }, "../..", b.allocator);

    const opts = b.addOptions();
    opts.addOption([]const u8, "gtk_theme", cg_opt.gtk_theme);
    exe.addOptions("opts", opts);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
