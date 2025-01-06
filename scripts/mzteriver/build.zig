const std = @import("std");
const common = @import("common");

const Scanner = @import("wayland").Scanner;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const CgOpt = struct {
        catppuccin: struct {
            base: [:0]const u8,
            red: [:0]const u8,
            sky: [:0]const u8,
        },
        nvidia: bool = false,
        term: struct { command: [:0]const u8 },
        commands: struct {
            file_manager: [:0]const u8,
            browser: [:0]const u8,
            media: struct {
                volume_up: [:0]const u8,
                volume_down: [:0]const u8,
                mute_sink: [:0]const u8,
                mute_source: [:0]const u8,

                play_pause: [:0]const u8,
                stop: [:0]const u8,
                next: [:0]const u8,
                prev: [:0]const u8,
            },
            backlight_up: [:0]const u8,
            backlight_down: [:0]const u8,
        },
        cursor: struct {
            theme: [:0]const u8,
            size: u32,
        },
    };
    const cg_opt = try common.confgenGet(CgOpt, b.allocator);

    const opts = b.addOptions();
    opts.addOption(CgOpt, "cg", cg_opt);

    const scanner = Scanner.create(b, .{});

    const exe = b.addExecutable(.{
        .name = "mzteriver",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    exe.root_module.addImport("common", b.dependency("common", .{}).module("common"));
    exe.root_module.addImport("opts", opts.createModule());
    exe.root_module.addImport("wayland", b.createModule(.{ .root_source_file = scanner.result }));

    scanner.addCustomProtocol(b.path("river-control-unstable-v1.xml"));

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
