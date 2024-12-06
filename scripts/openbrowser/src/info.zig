const std = @import("std");

pub const ProcessQuery = struct {
    name: []const u8,
    found_exepath: ?[]const u8 = null,

    pub fn deinit(self: *ProcessQuery, alloc: std.mem.Allocator) void {
        if (self.found_exepath) |p|
            alloc.free(p);

        self.* = undefined;
    }
};

pub fn query(alloc: std.mem.Allocator, queries: []ProcessQuery) !void {
    var proc_dir = try std.fs.openDirAbsolute("/proc", .{ .iterate = true });
    defer proc_dir.close();

    var proc_iter = proc_dir.iterate();
    procs: while (try proc_iter.next()) |proc| {
        // only look at directories which represent PIDs
        for (std.fs.path.basename(proc.name)) |c|
            if (!std.ascii.isDigit(c))
                continue :procs;

        var buf: [std.fs.max_path_bytes]u8 = undefined;
        const cmdline_f = std.fs.openFileAbsolute(
            try std.fmt.bufPrint(&buf, "/proc/{s}/cmdline", .{proc.name}),
            .{},
        ) catch |e| switch (e) {
            // skip other users' processes
            error.AccessDenied => continue,
            else => return e,
        };
        defer cmdline_f.close();

        // read first part of null-separated data (binary path)
        const exepath = epath: {
            var fbs = std.io.fixedBufferStream(&buf);
            cmdline_f.reader().streamUntilDelimiter(fbs.writer(), 0, null) catch |e| switch (e) {
                // occurs if there's no delimiter
                error.EndOfStream => {},
                else => return e,
            };
            break :epath fbs.getWritten();
        };

        var found_all = true;

        for (queries) |*q| {
            if (q.found_exepath) |_|
                continue;

            found_all = false;

            // this is a startsWith instead of an eql because the arguments in the
            // cmdline file are sometimes (and only sometimes!) separated by spaces
            // and not null bytes.
            if (!std.mem.startsWith(u8, std.fs.path.basename(exepath), q.name))
                continue;

            // Tor Browser's binary is named firefox. This trips this algorithm up, because it will
            // think firefox is running and attempt to start firefox. Since we don't want to open
            // Tor Browser anyways, we just special-case it.
            if (std.mem.containsAtLeast(u8, exepath, 1, "tor-browser"))
                continue;

            q.found_exepath = try alloc.dupe(u8, exepath);
        }

        if (found_all)
            break;
    }
}
