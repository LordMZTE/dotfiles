const std = @import("std");

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

    const nvide_argv = [_][]const u8{
        "neovide",
        "--nofork",
        "--x11-wm-class",
        "vinput-neovide",
        filename,
    };

    std.log.info("invoking neovide with command {s}", .{&nvide_argv});

    var nvide_child = std.ChildProcess.init(&nvide_argv, alloc);
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

        const xclip_argv = [_][]const u8{
            "xclip",
            "-sel",
            "clip",
        };

        std.log.info("invoking xclip with command {s}", .{&xclip_argv});

        var xclip_child = std.ChildProcess.init(&xclip_argv, alloc);
        xclip_child.stdin_behavior = .Pipe;
        try xclip_child.spawn();
        defer _ = xclip_child.wait() catch {};
        if (xclip_child.stdin == null) {
            return error.XclipNullStdin;
        }
        defer xclip_child.stdin = null;
        defer xclip_child.stdin.?.close();

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

        std.log.info("writing trimmed tempfile to xclip stdin", .{});
        try xclip_child.stdin.?.writeAll(std.mem.trim(u8, fcontent, " \n\r"));
    }
    std.log.info("deleting tempfile {s}", .{filename});
    try std.fs.deleteFileAbsolute(filename);
}
