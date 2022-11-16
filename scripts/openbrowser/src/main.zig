const std = @import("std");
const ProcessInfo = @import("ProcessInfo.zig");

pub const log_level = .debug;

const browsers = &[_][]const u8{
    "luakit",
    "waterfox-g4",
    "firefox",
    "chromium",
};

pub fn main() !void {
    if (std.os.argv.len < 2) {
        std.log.err("need >=1 argument", .{});
        return error.WrongArgs;
    }

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    for (browsers) |browser| {
        var info = try ProcessInfo.get(browser, alloc);
        defer info.deinit(alloc);

        if (!info.running)
            continue;

        std.log.info("found running browser {s}", .{info.exepath.?});

        try start(browser, alloc);
        return;
    }

    std.log.info("no running browser, using first choice", .{});
    try start(browsers[0], alloc);
}

fn start(browser: []const u8, alloc: std.mem.Allocator) !void {
    // args to browser will be same length as argv
    const argv = try alloc.alloc([]const u8, std.os.argv.len);
    defer alloc.free(argv);
    argv[0] = browser;

    for (std.os.argv[1..]) |arg, i| {
        argv[i + 1] = std.mem.span(arg);
    }

    std.log.info("child argv: {s}", .{argv});

    var child = std.ChildProcess.init(argv, alloc);
    _ = try child.spawnAndWait();
}
