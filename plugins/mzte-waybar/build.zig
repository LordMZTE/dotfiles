const std = @import("std");

// For each tag here, we'll build the library once and pass the given mode as an option.
const Mode = enum {
    separator,
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = b.createModule(.{
        .root_source_file = b.path("lib/main.zig"),
        .link_libc = true,
        .target = target,
        .optimize = optimize,
    });

    lib_mod.linkSystemLibrary("gtk+-3.0", .{});

    const common_mod = b.dependency("common", .{
        .target = target,
        .optimize = optimize,
    }).module("common");

    for (std.enums.values(Mode)) |mode| {
        const mod = b.createModule(.{
            .root_source_file = b.path(b.fmt("src/{t}.zig", .{mode})),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "lib", .module = lib_mod },
                .{ .name = "common", .module = common_mod },
            },
        });

        const lib = b.addLibrary(.{
            .name = b.fmt("mzte-waybar-{t}", .{mode}),
            .root_module = mod,
            .linkage = .dynamic,
            // TODO: https://github.com/ziglang/zig/issues/25026
            .use_llvm = true,
        });

        const install = b.addInstallArtifact(lib, .{
            // This is made up by me, not a standard waybar path.
            .dest_dir = .{ .override = .{ .custom = "share/waybar/cffi" } },
            .dest_sub_path = b.fmt("mzte-waybar-{t}.so", .{mode}),
        });

        b.getInstallStep().dependOn(&install.step);
    }
}
