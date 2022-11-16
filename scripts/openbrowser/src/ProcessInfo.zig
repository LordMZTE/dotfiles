const std = @import("std");

running: bool,
exepath: ?[]const u8,

const Self = @This();

/// Frees the data of this ProcessInfo.
/// `alloc` must be the same allocator that was supplied to `get`!
pub fn deinit(self: *Self, alloc: std.mem.Allocator) void {
    if (self.exepath) |exepath|
        alloc.free(exepath);
    self.* = undefined;
}

/// Gets information about a process given it's name
pub fn get(
    name: []const u8,
    alloc: std.mem.Allocator,
) !Self {
    var proc_dir = try std.fs.openIterableDirAbsolute("/proc", .{});
    defer proc_dir.close();

    var proc_iter = proc_dir.iterate();
    procs: while (try proc_iter.next()) |proc| {
        // Filter directories that aren't PIDs
        for (std.fs.path.basename(proc.name)) |letter|
            if (!std.ascii.isDigit(letter))
                continue :procs;

        var buf: [512]u8 = undefined;
        const cmdline_f = std.fs.openFileAbsolute(
            try std.fmt.bufPrint(&buf, "/proc/{s}/cmdline", .{proc.name}),
            .{},
        ) catch |e| {
            // This just happens when we're dealing with another user's process.
            if (e == error.AccessDenied)
                continue;

            return e;
        };

        defer cmdline_f.close();

        const cmdline_data = try cmdline_f.readToEndAlloc(alloc, std.math.maxInt(usize));
        defer alloc.free(cmdline_data);

        var cmdline_splits = std.mem.split(u8, cmdline_data, &.{0});
        const exepath = cmdline_splits.next() orelse return error.InvalidCmdline;

        // this is a startsWith instead of an eql because the arguments in the
        // cmdline file are sometimes (and only sometimes!) separated by spaces
        // and not null bytes.
        if (!std.mem.startsWith(u8, std.fs.path.basename(exepath), name))
            continue;

        return .{
            .running = true,
            .exepath = try alloc.dupe(u8, exepath),
        };
    }

    return .{
        .running = false,
        .exepath = null,
    };
}
