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

    fn make(step: *std.Build.Step, prog_node: std.Progress.Node) anyerror!void {
        _ = prog_node;
        const self: *InstallDepStep = @fieldParentPtr("step", step);

        var dir = try std.fs.cwd().openDir(self.dep.builder.install_prefix, .{
            .iterate = true,
        });
        defer dir.close();

        var iter = try dir.walk(step.owner.allocator);
        while (try iter.next()) |ent| {
            const outpath = step.owner.pathJoin(&.{ step.owner.install_prefix, ent.path });
            switch (ent.kind) {
                .directory => std.fs.cwd().makeDir(outpath) catch |e| switch (e) {
                    error.PathAlreadyExists => {},
                    else => return e,
                },
                else => {
                    const inpath = step.owner.pathJoin(&.{ self.dep.builder.install_prefix, ent.path });
                    try std.fs.cwd().copyFile(inpath, std.fs.cwd(), outpath, .{});
                },
            }
        }
    }
};
