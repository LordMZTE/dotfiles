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
    b.getInstallStep().dependOn(&InstallDepStep.init(b, dependency).step);
}

pub const InstallDepStep = struct {
    step: std.Build.Step,
    dep: *std.Build.Dependency,

    pub fn init(b: *std.Build, dep: *std.Build.Dependency) *InstallDepStep {
        const self = b.allocator.create(InstallDepStep) catch @panic("OOM");
        self.* = .{
            .step = std.Build.Step.init(.{
                .owner = b,
                .id = .custom,
                .name = "install-dep",
                .makeFn = make,
            }),
            .dep = dep,
        };

        self.step.dependOn(&dep.builder.install_tls.step);

        return self;
    }

    fn make(step: *std.Build.Step, options: std.Build.Step.MakeOptions) anyerror!void {
        _ = options;
        const self: *InstallDepStep = @fieldParentPtr("step", step);
        const io = self.dep.builder.graph.io;

        var dir = try std.Io.Dir.cwd().openDir(io, self.dep.builder.install_prefix, .{
            .iterate = true,
        });
        defer dir.close(io);

        var iter = try dir.walk(step.owner.allocator);
        while (try iter.next(io)) |ent| {
            const outpath = step.owner.pathJoin(&.{ step.owner.install_prefix, ent.path });
            switch (ent.kind) {
                .directory => std.Io.Dir.cwd().createDirPath(io, outpath) catch |e| switch (e) {
                    error.PathAlreadyExists => {},
                    else => return e,
                },
                else => {
                    const inpath = step.owner.pathJoin(&.{ self.dep.builder.install_prefix, ent.path });
                    try std.Io.Dir.cwd().copyFile(inpath, std.Io.Dir.cwd(), outpath, io, .{});
                },
            }
        }
    }
};

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
