const std = @import("std");
const Translator = @import("translate_c").Translator;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const translate_c = b.dependency("translate_c", .{});
    const translator: Translator = .init(translate_c, .{
        .c_source_file = b.path("c.h"),
        .target = target,
        .optimize = optimize,
        .link_system_libs = &.{
            .{.name = "ddcutil"},
        },
    });

    const mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{ .{
            .name = "common",
            .module = b.dependency("common", .{
                .target = target,
                .optimize = optimize,
            }).module("common"),
        }, .{
            .name = "args",
            .module = b.dependency("args", .{
                .target = target,
                .optimize = optimize,
            }).module("args"),
        }, .{
            .name = "c",
            .module = translator.mod,
        } },
        .link_libc = true,
    });

    const exe = b.addExecutable(.{
        .root_module = mod,
        .name = "brightness",
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.addPassthruArgs();
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
