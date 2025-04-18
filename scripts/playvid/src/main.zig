const std = @import("std");

pub const std_options = std.Options{
    .log_level = .debug,
    .logFn = @import("common").logFn,
};

pub fn main() !u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var file_buf: [std.fs.max_path_bytes]u8 = undefined;
    const file = try findVideoFile(alloc, &file_buf);

    try std.io.getStdOut().writer().print("playing: `{s}`\n", .{file});

    var child = std.process.Child.init(&.{ "mpv", file }, alloc);
    const term = try child.spawnAndWait();
    if (!std.meta.eql(term, .{ .Exited = 0 })) return 1;

    if (try promtForDeletion(file)) {
        try std.io.getStdOut().writer().print("deleting: `{s}`\n", .{file});
        try std.fs.cwd().deleteFile(file);

        // Also delete the live_chat file from yt-dlp if present
        if (std.mem.lastIndexOfScalar(u8, file, '.')) |dot_idx| {
            var fname_buf: [std.fs.max_path_bytes]u8 = undefined;
            const livechat_fname = try std.fmt.bufPrintZ(
                &fname_buf,
                "{s}.live_chat.json",
                .{file[0..dot_idx]},
            );

            std.fs.cwd().deleteFile(livechat_fname) catch |e| switch (e) {
                error.FileNotFound => {},
                else => return e,
            };
        }
    }

    return 0;
}

fn findVideoFile(alloc: std.mem.Allocator, out_buf: []u8) ![]const u8 {
    var basedir: []const u8 = ".";
    if (std.os.argv.len >= 2) {
        const arg = std.mem.span(std.os.argv[1]);
        if ((try std.fs.cwd().statFile(arg)).kind == .directory) {
            basedir = arg;
        } else {
            if (arg.len > out_buf.len) return error.OutOfMemory;
            @memcpy(out_buf[0..arg.len], arg);
            return out_buf[0..arg.len];
        }
    }

    var fname_arena = std.heap.ArenaAllocator.init(alloc);
    defer fname_arena.deinit();

    var cwd_iter = try std.fs.cwd().openDir(basedir, .{ .iterate = true });
    defer cwd_iter.close();
    var iter = cwd_iter.iterate();
    var files: std.ArrayListUnmanaged([]const u8) = .empty;
    defer files.deinit(alloc);

    while (try iter.next()) |entry| {
        switch (entry.kind) {
            .file => {
                if (std.mem.endsWith(u8, entry.name, ".live_chat.json"))
                    continue;

                try files.append(alloc, try fname_arena.allocator().dupe(u8, entry.name));
            },
            else => {},
        }
    }

    if (files.items.len == 0) return error.DirectoryEmpty;
    const idx = std.crypto.random.uintLessThan(usize, files.items.len);
    if (files.items[idx].len > out_buf.len) return error.OutOfMemory;
    @memcpy(out_buf[0..files.items[idx].len], files.items[idx]);
    return out_buf[0..files.items[idx].len];
}

fn promtForDeletion(file: []const u8) !bool {
    try std.io.getStdOut().writer().print("delete file `{s}`? [Y/N] ", .{file});

    const old_termios = try std.posix.tcgetattr(std.posix.STDIN_FILENO);
    var new_termios = old_termios;
    new_termios.lflag.ICANON = false; // No line buffering
    try std.posix.tcsetattr(std.posix.STDIN_FILENO, .NOW, new_termios);
    defer std.posix.tcsetattr(std.posix.STDIN_FILENO, .NOW, old_termios) catch {};

    const answer = try std.io.getStdIn().reader().readByte();
    const ret = switch (answer) {
        'y', 'Y' => true,
        else => false,
    };

    try std.io.getStdOut().writeAll("\n");
    return ret;
}
