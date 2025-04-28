const std = @import("std");

const inst = @import("setup/installers.zig");

const Options = @import("setup/Options.zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zargs = .{ .target = target, .optimize = optimize };

    const opts = try Options.parseConfig(b.allocator);

    // Symlink Scripts
    inst.addScript(b, opts, "brightness.rkt", "brightness");
    inst.addScript(b, opts, "map-touch-display.rkt", "map-touch-display");
    inst.addScript(b, opts, "pluto.jl", "pluto");
    inst.addScript(b, opts, "videos-duration.sh", "videos-duration");

    // Scripts
    inst.addZBuild(b, opts, zargs, "hyprtool");
    inst.addZBuild(b, opts, zargs, "mzteinit");
    inst.addZBuild(b, opts, zargs, "mzteriver");
    inst.addZBuild(b, opts, zargs, "openbrowser");
    inst.addZBuild(b, opts, zargs, "playvid");
    inst.addZBuild(b, opts, zargs, "prompt");
    inst.addZBuild(b, opts, zargs, "vinput");
    inst.addZBuild(b, opts, zargs, "withjava");
    inst.addZBuild(b, opts, zargs, "wlbg");

    // Plugins
    inst.addZBuild(b, opts, zargs, "mzte-mpv");
}
