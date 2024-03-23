const std = @import("std");
const common = @import("common");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});

    if (target.result.os.tag == .windows)
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
    }, b.allocator);

    const opts = b.addOptions();
    opts.addOption([]const u8, "font", cg_opt.term_font);
    lib.root_module.addImport("opts", opts.createModule());

    lib.root_module.addImport("nvim", znvim_dep.module("nvim_c"));
    lib.root_module.addImport("znvim", znvim_dep.module("znvim"));

    lib.linkLibC();
    lib.linkSystemLibrary("luajit");

    lib.root_module.unwind_tables = true;

    b.getInstallStep().dependOn(&b.addInstallFile(lib.getEmittedBin(), "share/nvim/mzte-nv.so").step);

    // this is the install step for the lua config compiler binary
    const compiler = b.addExecutable(.{
        .name = "mzte-nv-compile",
        .root_source_file = .{ .path = "src/compiler.zig" },
        .target = target,
        .optimize = mode,
    });

    compiler.linkLibC();
    compiler.linkSystemLibrary("luajit");

    compiler.root_module.addImport("common", b.dependency("common", .{}).module("common"));

    compiler.root_module.unwind_tables = true;

    b.installArtifact(compiler);
}
