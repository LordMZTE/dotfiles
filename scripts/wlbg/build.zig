const std = @import("std");
const common = @import("common");

const CgOpt = struct {
    catppuccin: struct { base: [:0]const u8 },
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const exe = b.addExecutable(.{
        .name = "wlbg",
        .root_module = mod,
    });

    mod.addImport("common", b.dependency("common", .{}).module("common"));
    mod.linkSystemLibrary("wayland-client", .{});
    mod.linkSystemLibrary("gdk-pixbuf-2.0", .{});

    const cg_opt = try common.confgenGet(CgOpt, b.allocator);
    const opts = b.addOptions();
    opts.addOption([:0]const u8, "ctp_base", cg_opt.catppuccin.base);

    mod.addImport("opts", opts.createModule());

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
