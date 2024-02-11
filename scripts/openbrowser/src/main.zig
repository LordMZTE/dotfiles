const std = @import("std");
const info = @import("info.zig");

pub const std_options = std.Options{
    .log_level = .debug,
};

const browsers = &[_][]const u8{
    "brave",
    "firefox",
    "luakit",
    "chromium",
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var queries: [browsers.len]info.ProcessQuery = undefined;
    for (browsers, &queries) |b, *q|
        q.* = .{ .name = b };

    try info.query(alloc, &queries);
    defer for (&queries) |*q| q.deinit(alloc);

    for (queries) |q| {
        if (q.found_exepath) |path| {
            std.log.info("found running browser: {s}", .{path});

            try start(q.name, alloc);
            return;
        }
    }

    std.log.info("no running browser, using first choice", .{});
    try start(browsers[0], alloc);
}

fn start(browser: []const u8, alloc: std.mem.Allocator) !void {
    // args to browser will be same length as argv
    const argv = try alloc.alloc([]const u8, std.os.argv.len);
    defer alloc.free(argv);
    argv[0] = browser;

    for (std.os.argv[1..], 0..) |arg, i| {
        argv[i + 1] = std.mem.span(arg);
    }

    std.log.info("child argv: {s}", .{argv});

    var child = std.ChildProcess.init(argv, alloc);
    _ = try child.spawnAndWait();
}
