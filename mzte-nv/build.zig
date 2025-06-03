const std = @import("std");
const common = @import("common");

const CgOpts = struct {
    nix: struct {
        nvim_plugins: ?[:0]u8 = null,
        tree_sitter_parsers: ?[:0]u8 = null,
        nvim_tools: ?[:0]u8 = null,
        jvm: ?[:0]u8 = null,
        @"fennel.lua": ?[:0]u8 = null,
    } = .{},
    textwidth: u16,
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const compiler_only = b.option(
        bool,
        "compiler-only",
        "only build the compiler",
    ) orelse false;

    if (target.result.os.tag == .windows)
        // windows is an error in many ways
        return error.Windows;

    const mode = b.standardOptimizeOption(.{});

    const common_dep = b.dependency("common", .{});

    // We fall back to defaults here in case we're building the compiler under Nix.
    const cg_opt = common.confgenGet(CgOpts, b.allocator) catch CgOpts{ .textwidth = 0 };

    const opts = b.addOptions();

    // Nix options
    opts.addOption(?[:0]const u8, "nvim_plugins", cg_opt.nix.nvim_plugins);
    opts.addOption(?[:0]const u8, "tree_sitter_parsers", cg_opt.nix.tree_sitter_parsers);
    opts.addOption(?[:0]const u8, "nvim_tools", cg_opt.nix.nvim_tools);
    opts.addOption(?[:0]const u8, "jvm", cg_opt.nix.jvm);
    opts.addOption(?[:0]const u8, "fennel.lua", cg_opt.nix.@"fennel.lua");

    // other options
    opts.addOption(u16, "textwidth", cg_opt.textwidth);

    if (!compiler_only) {
        const lib = b.addSharedLibrary(.{
            .name = "mzte-nv",
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = mode,
        });

        if (b.lazyDependency(
            "znvim",
            .{ .target = target, .optimize = mode },
        )) |znvim_dep| {
            lib.root_module.addImport("nvim", znvim_dep.module("nvim_c"));
            lib.root_module.addImport("znvim", znvim_dep.module("znvim"));
        }

        lib.root_module.addImport("opts", opts.createModule());
        lib.root_module.addImport("common", common_dep.module("common"));

        lib.linkLibC();
        lib.linkSystemLibrary("luajit");

        // I have no idea what the difference between async and sync is here, but this works.
        lib.root_module.unwind_tables = .@"async";

        b.getInstallStep().dependOn(&b.addInstallFile(lib.getEmittedBin(), "share/nvim/mzte-nv.so").step);
    }

    // this is the install step for the lua config compiler binary
    const compiler = b.addExecutable(.{
        .name = "mzte-nv-compile",
        .root_source_file = b.path("src/compiler.zig"),
        .target = target,
        .optimize = mode,
    });

    compiler.linkLibC();
    compiler.linkSystemLibrary("luajit");

    compiler.root_module.addImport("opts", opts.createModule());
    compiler.root_module.addImport("common", b.dependency("common", .{}).module("common"));

    compiler.root_module.unwind_tables = .@"async";

    b.installArtifact(compiler);
}
