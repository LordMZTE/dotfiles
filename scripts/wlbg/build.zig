const std = @import("std");
const common = @import("common");

const CgOpt = struct {
    catppuccin: struct { base: [:0]const u8 },
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const exe = b.addExecutable(.{
        .name = "wlbg",
        .root_module = mod,
    });

    mod.addImport("common", b.dependency("common", .{
        .target = target,
        .optimize = optimize,
    }).module("common"));
    mod.linkSystemLibrary("wayland-client", .{});
    mod.linkSystemLibrary("gdk-pixbuf-2.0", .{});

    mod.addAnonymousImport("cg", .{
        .root_source_file = common.confgenPath(b, "cgassets/constsiz_opts.zon"),
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
