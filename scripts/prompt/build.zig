const std = @import("std");
const Translator = @import("translate_c").Translator;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardOptimizeOption(.{});

    const translate_c = b.dependency("translate_c", .{});
    const translator: Translator = .init(translate_c, .{
        .c_source_file = b.path("c.h"),
        .target = target,
        .optimize = mode,
        .link_system_libs = &.{
            .{ .name = "libgit2" },
        },
    });

    const mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = mode,
        .imports = &.{
            .{ .name = "c", .module = translator.mod },
            .{ .name = "common", .module = b.dependency("common", .{
                .target = target,
                .optimize = mode,
            }).module("common") },
            .{ .name = "ansi-term", .module = b.dependency("ansi_term", .{}).module("ansi_term") },
        },
    });

    const exe = b.addExecutable(.{
        .name = "prompt",
        .root_module = mod,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.addPassthruArgs();

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
