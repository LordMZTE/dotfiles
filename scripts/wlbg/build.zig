const std = @import("std");
const common = @import("common");

const Scanner = @import("wayland").Scanner;

const CgOpt = struct {
    catppuccin: struct { base: [:0]const u8 },
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "wlbg",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const scanner = Scanner.create(b, .{});
    const wayland_mod = b.createModule(.{ .root_source_file = scanner.result });

    exe.root_module.addImport("common", b.dependency("common", .{}).module("common"));
    exe.root_module.addImport("wayland", wayland_mod);

    scanner.generate("wl_seat", 4);
    scanner.generate("wl_output", 4);

    exe.root_module.linkSystemLibrary("wayland-client", .{});
    exe.root_module.linkSystemLibrary("gdk-pixbuf-2.0", .{});

    const cg_opt = try common.confgenGet(CgOpt, b.allocator);
    const opts = b.addOptions();
    opts.addOption([:0]const u8, "ctp_base", cg_opt.catppuccin.base);

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
