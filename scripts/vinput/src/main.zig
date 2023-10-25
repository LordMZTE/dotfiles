const std = @import("std");
const c = @import("ffi.zig").c;
const ClipboardConnection = @import("ClipboardConnection.zig");

pub const std_options = struct {
    pub const log_level = .debug;
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    if (std.os.argv.len == 1 or std.os.argv.len > 2) {
        std.log.err(
            \\ Invalid usage.
            \\ Usage: {s} FILE_EXTENSION
        , .{std.os.argv[0]});
        return error.InvalidCli;
    }

    var alloc = gpa.allocator();

    const filename = try std.fmt.allocPrint(
        alloc,
        "/tmp/vinput{}-{}.{s}",
        .{ std.os.linux.getuid(), std.time.milliTimestamp(), std.os.argv[1] },
    );
    defer alloc.free(filename);

    var cp = try ClipboardConnection.init();
    defer cp.deinit();

    {
        const file = try std.fs.createFileAbsolute(filename, .{});
        defer file.close();

        std.log.info("telling compositor to write clipboard content into tmpfile...", .{});
        try cp.getContent(file.handle);
    }

    //const editor_argv = [_][]const u8{
    //    "neovide",
    //    "--nofork",
    //    "--wayland_app_id",
    //    "vinput-editor",
    //    filename,
    //};

    const editor_argv = [_][]const u8{
        "foot",
        "--app-id",
        "vinput-editor",
        "--",
        "nvim",
        "--cmd",
        "let g:started_by_vinput=v:true",
        filename,
    };

    std.log.info("invoking editor with command {s}", .{&editor_argv});

    var nvide_child = std.ChildProcess.init(&editor_argv, alloc);
    _ = try nvide_child.spawnAndWait();

    const stat = std.fs.cwd().statFile(filename) catch |e| {
        switch (e) {
            error.FileNotFound => {
                std.log.warn("tempfile doesn't exist; aborting", .{});
                return;
            },
            else => return e,
        }
    };
    mmap: {
        if (stat.size == 0) {
            std.log.info("empty file", .{});
            break :mmap;
        }

        var tempfile = try std.fs.openFileAbsolute(filename, .{});
        defer tempfile.close();

        std.log.info("mmapping tempfile", .{});

        const fcontent = try std.os.mmap(
            null,
            stat.size,
            std.os.PROT.READ,
            std.os.MAP.PRIVATE,
            tempfile.handle,
            0,
        );
        defer std.os.munmap(fcontent);

        try cp.serveContent(std.mem.trim(u8, fcontent, " \n\r"));
    }
    std.log.info("deleting tempfile {s}", .{filename});
    try std.fs.deleteFileAbsolute(filename);
}
