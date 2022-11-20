const std = @import("std");

const log = std.log.scoped(.compiler);

pub const log_level = .debug;

pub fn main() !void {
    if (std.os.argv.len != 2) {
        log.err(
            \\Usage: {s} [dir]
            \\
            \\`input` is a path to a normal lua neovim configuration
            \\(or any other path containing lua files.)
        ,
            .{std.os.argv[0]},
        );

        return error.InvalidArgs;
    }

    const input_arg = std.mem.span(std.os.argv[1]);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    try doCompile(input_arg, gpa.allocator());
}

pub fn doCompile(path: []const u8, alloc: std.mem.Allocator) !void {
    var dir = try std.fs.cwd().openIterableDir(path, .{});
    defer dir.close();

    var walker = try dir.walk(alloc);
    defer walker.deinit();

    // a list of lua files to compile
    var files = std.ArrayList([]const u8).init(alloc);
    defer files.deinit();

    // an arena allocator to hold data to be used during the build
    var build_arena = std.heap.ArenaAllocator.init(alloc);
    defer build_arena.deinit();
    const build_alloc = build_arena.allocator();

    while (try walker.next()) |entry| {
        const entry_path = try std.fs.path.join(build_alloc, &.{ path, entry.path });

        switch (entry.kind) {
            .File => {
                if (std.mem.endsWith(u8, entry.path, ".lua")) {
                    try files.append(entry_path);
                }
            },
            else => {},
        }
    }

    // a buffer containing the content of the currently compiling lua file
    var content_buf = std.ArrayList(u8).init(alloc);
    defer content_buf.deinit();

    for (files.items) |luafile| {
        content_buf.clearRetainingCapacity();

        var lfile = try std.fs.cwd().openFile(luafile, .{});
        defer lfile.close();
        var lfifo = std.fifo.LinearFifo(u8, .{ .Static = 1024 * 64 }).init();
        try lfifo.pump(lfile.reader(), content_buf.writer());

        const argv = try build_alloc.allocSentinel(
            ?[*:0]const u8,
            5,
            null,
        );

        // TODO: maybe try doing this through to luajit C api instead of a process?
        // not sure if that's possible
        argv[0] = "luajit";
        argv[1] = "-O9";
        argv[2] = "-b";
        argv[3] = "-";
        argv[4] = try std.cstr.addNullByte(build_alloc, luafile);

        // Doing it the C way because zig's ChildProcess ain't got this
        const pipe = try std.os.pipe2(0);
        const pid = try std.os.fork();
        if (pid == 0) {
            std.os.close(pipe[1]);
            try std.os.dup2(pipe[0], 0);
            return std.os.execvpeZ(argv[0].?, argv, std.c.environ);
        }

        std.os.close(pipe[0]);

        try (std.fs.File{ .handle = pipe[1] }).writeAll(content_buf.items);

        std.os.close(pipe[1]);
        if (std.os.waitpid(pid, 0).status != 0) {
            log.warn("luajit crashed compiling {s}, skipping", .{luafile});
        }
    }
    log.info("compiled {} lua objects @ {s}", .{ files.items.len, path });
}
