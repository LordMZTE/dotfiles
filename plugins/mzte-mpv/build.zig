const std = @import("std");
const common = @import("common");

const Translator = @import("translate_c").Translator;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // For each tag here, we'll build the library once and pass the given mode as an option.
    const translate_c = b.dependency("translate_c", .{});
    const translator: Translator = .init(translate_c, .{
        .c_source_file = b.path("c.h"),
        .target = target,
        .optimize = optimize,
        .link_system_libs = &.{
            // Linking MPV for a plugin is usually undesirable, but it seems to work anyways.
            // This is here because Zig will otherwise not find the necessary header files on NixOS,
            // and there appears to be no way to obtain an include path using pkg-config without
            // also linking.
            .{ .name = "mpv" },
        },
    });

    const mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .link_libc = true,
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "c", .module = translator.mod },
        },
    });

    const lib = b.addLibrary(.{
        .name = "mzte-mpv",
        .root_module = mod,
        .linkage = .dynamic,
    });
    mod.addImport("common", b.dependency("common", .{
        .target = target,
        .optimize = optimize,
    }).module("common"));
    mod.addImport("ansi-term", b.dependency("ansi_term", .{}).module("ansi_term"));

    mod.addAnonymousImport("cg", .{
        .root_source_file = common.confgenPath(b, "cgassets/constsiz_opts.zon"),
    });

    const install_step = b.addInstallArtifact(lib, .{
        // this is not a standard MPV installation path, but instead one that makes sense.
        // this requires a symlink ../../../.local/share/mpv/scripts => ~/.config/mpv/scripts
        .dest_dir = .{ .override = .{ .custom = "share/mpv/scripts" } },
        .dest_sub_path = "mzte-mpv.so",
    });
    b.getInstallStep().dependOn(&install_step.step);
}
