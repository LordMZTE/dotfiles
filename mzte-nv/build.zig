const std = @import("std");
const common = @import("common");

const CgOpts = struct {
    nix: struct {
        nvim_plugins: ?[:0]const u8 = null,
        nvim_tools: ?[:0]const u8 = null,
        jvm: ?[:0]const u8 = null,
        @"fennel.lua": ?[:0]const u8 = null,
    } = .{},
    textwidth: u16,
    font: [:0]const u8,
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

    const common_dep = b.dependency("common", .{
        .target = target,
        .optimize = mode,
    });

    const opts_path = common.confgenPath(b, "cgassets/mzte-nv-opts.zon");
    const opts_mod = b.createModule(.{
        .root_source_file = if (std.fs.cwd().access(opts_path.cwd_relative, .{}))
            opts_path
        else |_|
            b.path("fallback-opts.zon"),
    });

    if (!compiler_only) {
        const lib_mod = b.addModule("mzte-nv", .{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = mode,
        });

        const lib = b.addLibrary(.{
            .name = "mzte-nv",
            .linkage = .dynamic,
            .root_module = lib_mod,

            // Compiler segfaults without this
            // TODO: investigate
            .use_llvm = true,
        });

        if (b.lazyDependency(
            "znvim",
            .{ .target = target, .optimize = mode },
        )) |znvim_dep| {
            lib.root_module.addImport("nvim", znvim_dep.module("nvim_c"));
            lib.root_module.addImport("znvim", znvim_dep.module("znvim"));
        }

        lib.root_module.addImport("opts", opts_mod);
        lib.root_module.addImport("common", common_dep.module("common"));
        lib.root_module.addImport("lualib", common_dep.module("lualib"));

        // I have no idea what the difference between async and sync is here, but this works.
        lib.root_module.unwind_tables = .async;

        b.getInstallStep().dependOn(&b.addInstallFile(lib.getEmittedBin(), "share/nvim/mzte-nv.so").step);
    }

    const compiler_mod = b.createModule(.{
        .root_source_file = b.path("src/compiler.zig"),
        .target = target,
        .optimize = mode,
    });

    // this is the install step for the lua config compiler binary
    const compiler = b.addExecutable(.{
        .name = "mzte-nv-compile",
        .root_module = compiler_mod,
    });

    compiler.root_module.addImport("opts", opts_mod);
    compiler.root_module.addImport("common", common_dep.module("common"));
    compiler.root_module.addImport("lualib", common_dep.module("lualib"));

    compiler.root_module.unwind_tables = .async;

    b.installArtifact(compiler);
}
