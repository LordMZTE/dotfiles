const std = @import("std");
const clipboard = @import("clipboard.zig");

pub const log_level = .debug;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var alloc = gpa.allocator();

    const filename = try std.fmt.allocPrint(
        alloc,
        "/tmp/vinput{}-{}",
        .{ std.os.linux.getuid(), std.time.milliTimestamp() },
    );
    defer alloc.free(filename);

    //const editor_argv = [_][]const u8{
    //    "neovide",
    //    "--nofork",
    //    "--x11-wm-class",
    //    "vinput-neovide",
    //    filename,
    //};

    const editor_argv = [_][]const u8{
        "alacritty",
        "--class",
        "vinput-neovide",
        "-e",
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
    {
        var tempfile = try std.fs.openFileAbsolute(filename, .{});
        defer tempfile.close();

        std.log.info("mmapping tempfile", .{});

        // ooooh memmap, performance!
        const fcontent = try std.os.mmap(
            null,
            stat.size,
            std.os.PROT.READ,
            std.os.MAP.PRIVATE,
            tempfile.handle,
            0,
        );
        defer std.os.munmap(fcontent);

        try clipboard.provideClipboard(std.mem.trim(u8, fcontent, " \n\r"), alloc);
    }
    std.log.info("deleting tempfile {s}", .{filename});
    try std.fs.deleteFileAbsolute(filename);
}
