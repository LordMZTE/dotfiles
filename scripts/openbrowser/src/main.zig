const std = @import("std");
const common = @import("common");

const info = @import("info.zig");

pub const std_options = std.Options{
    .log_level = .debug,
    .logFn = @import("common").logFn,
};

const browsers = &[_][]const u8{
    "qutebrowser",
    "librewolf",
    "firefox",
    "brave",
    "luakit",
    "Ladybird",
    "chromium",
};

pub fn main(init: std.process.Init) !void {
    const alloc = init.gpa;

    var queries: [browsers.len]info.ProcessQuery = undefined;
    for (browsers, &queries) |b, *q|
        q.* = .{ .name = b };

    try info.query(alloc, init.io, &queries);
    defer for (&queries) |*q| q.deinit(alloc);

    for (queries) |q| {
        if (q.found_exepath) |path| {
            std.log.info("found running browser: {s}", .{path});

            try start(alloc, init.io, init.minimal.args.vector, q.name);
            return;
        }
    }

    std.log.info("no running browser, using first choice", .{});
    try start(alloc, init.io, init.minimal.args.vector, browsers[0]);
}

fn start(alloc: std.mem.Allocator, io: std.Io, this_argv: []const [*:0]const u8, browser: []const u8,) !void {
    // args to browser will be same length as argv
    const argv = try alloc.alloc([]const u8, this_argv.len);
    defer alloc.free(argv);
    argv[0] = browser;

    for (this_argv[1..], argv[1..]) |arg, *childarg| {
        childarg.* = std.mem.span(arg);
    }

    // Luakit and qutebrowser don't support conventional 'app' mode, so instead, we just open the page normally.
    if (std.mem.eql(u8, browser, "luakit") or std.mem.eql(u8, browser, "qutebrowser")) {
        for (argv) |*arg| {
            if (arg.len > 6 and std.mem.startsWith(u8, arg.*, "--app=")) {
                arg.* = arg.*[6..];
            }
        }
    }

    std.log.info("child argv: {f}", .{common.fmt.command(argv)});

    var child = try std.process.spawn(io, .{ .argv = argv });
    _ = try child.wait(io);
}
