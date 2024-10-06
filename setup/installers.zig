const std = @import("std");

const Options = @import("Options.zig");

pub fn addScript(b: *std.Build, opts: Options, src: []const u8, dest: []const u8) void {
    if (opts.isBlacklisted(dest)) return;
    b.installFile(
        b.fmt("scripts/{s}", .{src}),
        b.fmt("bin/{s}", .{dest}),
    );
}

pub fn addZBuild(b: *std.Build, opts: Options, args: anytype, dep: []const u8) void {
    if (opts.isBlacklisted(dep)) return;
    for (b.dependency(dep, args).builder.install_tls.step.dependencies.items) |d| {
        b.installArtifact((d.cast(std.Build.Step.InstallArtifact) orelse continue).artifact);
    }
}
