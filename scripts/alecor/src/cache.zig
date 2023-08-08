const std = @import("std");

pub fn commandsCachePath(alloc: std.mem.Allocator) ![]const u8 {
    return try std.fs.path.join(alloc, &.{
        std.os.getenv("HOME") orelse return error.HomeNotSet,
        ".cache",
        "alecor",
        "commands",
    });
}

pub fn generate(alloc: std.mem.Allocator) !void {
    const cache_path = try commandsCachePath(alloc);
    defer alloc.free(cache_path);

    if (std.fs.path.dirname(cache_path)) |cache_dir| {
        try std.fs.cwd().makePath(cache_dir);
    }

    var cache_file = try std.fs.cwd().createFile(cache_path, .{});
    defer cache_file.close();

    const pipefds = try std.os.pipe();
    defer std.os.close(pipefds[0]);

    var stdout_buf_reader = std.io.bufferedReader((std.fs.File{ .handle = pipefds[0] }).reader());

    // ChildProcess being useless again...
    const pid = try std.os.fork();
    if (pid == 0) {
        errdefer std.os.exit(1);
        try std.os.dup2(pipefds[1], 1);
        std.os.close(pipefds[0]);
        std.os.close(pipefds[1]);
        return std.os.execvpeZ(
            "fish",
            &[_:null]?[*:0]const u8{ "fish", "-c", "complete -C ''" },
            @ptrCast(std.os.environ.ptr),
        );
    }

    std.os.close(pipefds[1]);

    var cmd_buf: [1024]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&cmd_buf);
    while (true) {
        fbs.reset();
        stdout_buf_reader.reader().streamUntilDelimiter(fbs.writer(), '\n', null) catch |e| switch (e) {
            error.EndOfStream => break,
            else => return e,
        };

        // FBS will have <cmd>\tgarbage here
        var spliter = std.mem.tokenize(u8, fbs.getWritten(), "\t");
        try cache_file.writeAll(spliter.next() orelse continue);
        try cache_file.writer().writeByte('\n');
    }

    _ = std.os.waitpid(pid, 0);
}
