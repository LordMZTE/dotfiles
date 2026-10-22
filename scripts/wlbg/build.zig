const std = @import("std");
const common = @import("common");
const Translator = @import("translate_c").Translator;

const CgOpt = struct {
    catppuccin: struct { base: [:0]const u8 },
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const translate_c = b.dependency("translate_c", .{});
    const translator: Translator = .init(translate_c, .{
        .c_source_file = b.path("c.h"),
        .target = target,
        .optimize = optimize,
        .link_system_libs = &.{
            .{ .name = "gdk-pixbuf-2.0" },
        },
    });

    const mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .imports = &.{
            .{ .name = "c", .module = translator.mod },
            .{ .name = "common", .module = b.dependency("common", .{
                .target = target,
                .optimize = optimize,
            }).module("common") },
        },
    });

    const exe = b.addExecutable(.{
        .name = "wlbg",
        .root_module = mod,
    });

    mod.addAnonymousImport("cg", .{
        .root_source_file = common.confgenPath(b, "cgassets/constsiz_opts.zon"),
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.addPassthruArgs();

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
