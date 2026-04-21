const std = @import("std");
const common = @import("common");

const ClipboardConnection = @import("ClipboardConnection.zig");

pub const std_options = std.Options{
    .log_level = .debug,
    .logFn = @import("common").logFn,
};

pub fn main(init: std.process.Init) !void {
    const argv = init.minimal.args.vector;

    if (argv.len == 1 or argv.len > 2) {
        std.log.err(
            \\ Invalid usage.
            \\ Usage: {s} FILE_EXTENSION
        , .{argv[0]});
        return error.InvalidCli;
    }

    const filename = try std.fmt.allocPrint(
        init.gpa,
        "/tmp/vinput{}-{}.{s}",
        .{ std.os.linux.getuid(), std.os.linux.getpid(), argv[1] },
    );
    defer init.gpa.free(filename);

    var cp = try ClipboardConnection.init();
    defer cp.deinit();

    {
        const file = try std.Io.Dir.createFileAbsolute(init.io, filename, .{});
        defer file.close(init.io);

        std.log.info("telling compositor to write clipboard content into tmpfile...", .{});
        try cp.getContent(file.handle);
    }

    //const editor_argv = [_][]const u8{
    //    "neovide",
    //    "--no-fork",
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

    std.log.info("invoking editor with command {f}", .{common.fmt.command(&editor_argv)});

    var editor_child = try std.process.spawn(init.io, .{ .argv = &editor_argv });
    _ = try editor_child.wait(init.io);

    const stat = std.Io.Dir.cwd().statFile(init.io, filename, .{}) catch |e| {
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

        var tempfile = try std.Io.Dir.openFileAbsolute(init.io, filename, .{});
        defer tempfile.close(init.io);

        std.log.info("mmapping tempfile", .{});

        const fcontent = try std.posix.mmap(
            null,
            stat.size,
            .{ .READ = true },
            .{ .TYPE = .PRIVATE },
            tempfile.handle,
            0,
        );
        defer std.posix.munmap(fcontent);

        try cp.serveContent(std.mem.trim(u8, fcontent, " \n\r"));
    }
    std.log.info("deleting tempfile {s}", .{filename});
    try std.Io.Dir.deleteFileAbsolute(init.io, filename);
}
