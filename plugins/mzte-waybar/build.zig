const std = @import("std");
const Translator = @import("translate_c").Translator;

// For each tag here, we'll build the library once and pass the given mode as an option.
const Mode = enum {
    separator,
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const translate_c = b.dependency("translate_c", .{});
    const translator: Translator = .init(translate_c, .{
        .c_source_file = b.path("c.h"),
        .target = target,
        .optimize = optimize,
        .link_system_libs = &.{
            .{.name = "gtk+-3.0"},
        },
    });

    const lib_mod = b.createModule(.{
        .root_source_file = b.path("lib/main.zig"),
        .link_libc = true,
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "c", .module = translator.mod },
        },
    });

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
                .{ .name = "c", .module = translator.mod },
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
