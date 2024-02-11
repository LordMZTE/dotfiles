const std = @import("std");
const common = @import("build_common.zig");

const Scanner = @import("wayland").Scanner;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const cg_opt = try common.confgenGet(struct { nvidia: bool = false, term: struct { command: [:0]const u8 }, commands: struct {
        file_manager: [:0]const u8,
        browser: [:0]const u8,
    }, cursor: struct {
        theme: [:0]const u8,
        size: u32,
    } }, "../..", b.allocator);

    const opts = b.addOptions();
    opts.addOption(bool, "nvidia", cg_opt.nvidia);
    opts.addOption([:0]const u8, "term_command", cg_opt.term.command);
    opts.addOption([:0]const u8, "file_manager_command", cg_opt.commands.file_manager);
    opts.addOption([:0]const u8, "browser_command", cg_opt.commands.browser);
    opts.addOption([:0]const u8, "cursor_theme", cg_opt.cursor.theme);
    opts.addOption(u32, "cursor_size", cg_opt.cursor.size);

    const scanner = Scanner.create(b, .{});

    const exe = b.addExecutable(.{
        .name = "mzteriver",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("opts", opts.createModule());
    exe.root_module.addImport("wayland", scanner.mod);

    scanner.addCustomProtocol("river-control-unstable-v1.xml");

    scanner.generate("zriver_control_v1", 1);
    scanner.generate("wl_seat", 7);

    exe.root_module.linkSystemLibrary("wayland-client", .{});

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
