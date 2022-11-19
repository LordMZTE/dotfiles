const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
    if (@import("builtin").os.tag == .windows)
        @compileError("no lol");
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const lib = b.addSharedLibrary("mzte-nv", "src/main.zig", .unversioned);
    lib.setBuildMode(mode);

    lib.linkLibC();
    lib.linkSystemLibrary("luajit");

    lib.strip = mode != .Debug;
    lib.unwind_tables = true;

    b.getInstallStep().dependOn(&(try InstallStep.init(b, lib)).step);

    // this is the install step for the lua config compiler binary
    const compiler = b.addExecutable("mzte-nv-compile", "src/compiler.zig");
    compiler.setBuildMode(mode);

    compiler.linkLibC();

    compiler.strip = mode != .Debug;

    compiler.install();
}

const InstallStep = struct {
    builder: *std.build.Builder,
    step: std.build.Step,
    lib: *std.build.LibExeObjStep,

    fn init(builder: *std.build.Builder, lib: *std.build.LibExeObjStep) !*InstallStep {
        const self = try builder.allocator.create(InstallStep);
        self.* = .{
            .builder = builder,
            .lib = lib,
            .step = std.build.Step.init(.custom, "install", builder.allocator, make),
        };
        self.step.dependOn(&lib.step);
        return self;
    }

    fn make(step: *std.build.Step) anyerror!void {
        const self = @fieldParentPtr(InstallStep, "step", step);

        const plugin_install_dir = std.build.InstallDir{
            .custom = "share/nvim",
        };
        const plugin_basename = "mzte-nv.so";

        const dest_path = self.builder.getInstallPath(
            plugin_install_dir,
            plugin_basename,
        );

        try self.builder.updateFile(
            self.lib.getOutputSource().getPath(self.builder),
            dest_path,
        );

        // FIXME: the uninstall step doesn't do anything, despite this
        self.builder.pushInstalledFile(plugin_install_dir, plugin_basename);
    }
};
