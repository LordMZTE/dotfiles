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
    const dependency = b.dependency(dep, args);
    b.getInstallStep().dependOn(dependency.builder.getInstallStep());
    //b.getInstallStep().dependOn(&InstallDepStep.init(b, dependency).step);
}

pub fn addHaskellScript(
    b: *std.Build,
    opts: Options,
    optimize: std.builtin.OptimizeMode,
    name: []const u8,
) void {
    if (opts.isBlacklisted(name)) return;

    var source_buf: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const source = b.path(std.fmt.bufPrint(
        &source_buf,
        "scripts/{s}.hs",
        .{name},
    ) catch @panic("OOM"));

    const opt = switch (optimize) {
        .Debug => "-O0",
        .ReleaseSafe => "-O1",
        .ReleaseFast, .ReleaseSmall => "-O2",
    };

    const run = b.addSystemCommand(&.{ "ghc", opt });
    run.addFileArg(source);
    run.addArg("-o");
    const output = run.addOutputFileArg(name);
    run.addArg("-outputdir");
    _ = run.addOutputDirectoryArg("hs");

    const install = b.addInstallBinFile(output, name);
    b.getInstallStep().dependOn(&install.step);
}
