const std = @import("std");
const common = @import("build_common.zig");

pub fn build(b: *std.build.Builder) !void {
    const target = b.standardTargetOptions(.{});

    if (target.os_tag orelse @import("builtin").os.tag == .windows)
        // windows is an error in many ways
        return error.Windows;

    const mode = b.standardOptimizeOption(.{});

    const lib = b.addSharedLibrary(.{
        .name = "mzte-nv",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = mode,
    });

    const znvim_dep = b.dependency("znvim", .{ .target = target, .optimize = mode });

    const cg_opt = try common.confgenGet(struct {
        term_font: []u8, // TODO: this being non-const is a workaround for an std bug
    }, "..", b.allocator);

    const opts = b.addOptions();
    opts.addOption([]const u8, "font", cg_opt.term_font);
    lib.addOptions("opts", opts);

    lib.addModule("nvim", znvim_dep.module("nvim_c"));
    lib.addModule("znvim", znvim_dep.module("znvim"));

    lib.linkLibC();
    lib.linkSystemLibrary("luajit");

    lib.strip = switch (mode) {
        .Debug, .ReleaseSafe => false,
        .ReleaseFast, .ReleaseSmall => true,
    };
    lib.unwind_tables = true;

    b.getInstallStep().dependOn(&b.addInstallFile(lib.getOutputSource(), "share/nvim/mzte-nv.so").step);

    // this is the install step for the lua config compiler binary
    const compiler = b.addExecutable(.{
        .name = "mzte-nv-compile",
        .root_source_file = .{ .path = "src/compiler.zig" },
        .target = target,
        .optimize = mode,
    });

    compiler.linkLibC();
    compiler.linkSystemLibrary("luajit");

    compiler.strip = mode != .Debug;
    compiler.unwind_tables = true;

    b.installArtifact(lib);
}
