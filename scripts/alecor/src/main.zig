const std = @import("std");

const cache = @import("cache.zig");
const util = @import("util.zig");

pub const std_options = std.Options{
    .log_level = .debug,
    .logFn = @import("common").logFn,
};

pub fn main() !void {
    if (std.os.argv.len < 2)
        return error.NotEnoughArguments;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const subcmd = std.mem.span(std.os.argv[1]);

    if (std.mem.eql(u8, subcmd, "doalec")) {
        if (std.os.argv.len < 3)
            return error.NotEnoughArguments;

        var args = std.ArrayList([]const u8).init(alloc);
        defer args.deinit();

        var spliter = std.mem.tokenize(u8, std.mem.span(std.os.argv[2]), "\n");
        while (spliter.next()) |arg|
            try args.append(arg);

        // open and map cache
        const cache_path = try cache.commandsCachePath(alloc);
        defer alloc.free(cache_path);

        var cache_file = try std.fs.cwd().openFile(cache_path, .{});
        defer cache_file.close();

        const cache_content = try std.os.mmap(
            null,
            (try cache_file.stat()).size,
            std.os.PROT.READ,
            .{ .TYPE = .PRIVATE },
            cache_file.handle,
            0,
        );
        defer std.os.munmap(cache_content);

        var command_set = std.StringHashMap(void).init(alloc);
        defer command_set.deinit();

        var cache_tok = std.mem.tokenize(u8, cache_content, "\n");
        while (cache_tok.next()) |tok|
            if (tok.len != 0)
                try command_set.put(tok, {});

        var arena = std.heap.ArenaAllocator.init(alloc);
        defer arena.deinit();

        try @import("correct.zig").correctCommand(&arena, args.items, &command_set);
        try std.io.getStdOut().writer().print("{}\n", .{util.fmtCommand(args.items)});
    } else if (std.mem.eql(u8, subcmd, "printfish")) {
        try std.io.getStdOut().writer().print(
            \\function alec --description 'ALEC'
            \\    commandline (builtin history search -n 1)
            \\    commandline ({s} doalec (commandline -o | string split0))
            \\end
            \\
        , .{std.os.argv[0]});
    } else if (std.mem.eql(u8, subcmd, "mkcache")) {
        try cache.generate(alloc);
    } else return error.UnknownCommand;
}
