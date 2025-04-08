const std = @import("std");

files: std.ArrayListUnmanaged([:0]u8),
alloc: std.mem.Allocator,
filename_arena: std.heap.ArenaAllocator,

const Self = @This();

pub fn init(alloc: std.mem.Allocator) Self {
    return Self{
        .files = .empty,
        .alloc = alloc,
        .filename_arena = std.heap.ArenaAllocator.init(alloc),
    };
}

pub fn deinit(self: *Self) void {
    self.filename_arena.deinit();
    self.files.deinit(self.alloc);
}

pub fn walk(self: *Self, dir: std.fs.Dir) anyerror!void {
    var iter = dir.iterate();
    while (try iter.next()) |e| {
        switch (e.kind) {
            .file => {
                var rpath_buf: [std.fs.max_path_bytes]u8 = undefined;
                const path = try self.filename_arena.allocator().dupeZ(
                    u8,
                    try dir.realpath(e.name, &rpath_buf),
                );
                try self.files.append(self.alloc, path);
            },
            .directory => {
                var subdir = try dir.openDir(e.name, .{ .iterate = true });
                defer subdir.close();
                try self.walk(subdir);
            },
            .sym_link => {
                var p_buf: [std.fs.max_path_bytes]u8 = undefined;
                const p = try dir.readLink(e.name, &p_buf);
                var subdir = dir.openDir(p, .{ .iterate = true }) catch |err| {
                    switch (err) {
                        error.NotDir => {
                            const fpath = try self.filename_arena.allocator().dupeZ(u8, p);
                            try self.files.append(self.alloc, fpath);
                            continue;
                        },
                        else => return err,
                    }
                };
                defer subdir.close();

                try self.walk(subdir);
            },
            else => {},
        }
    }
}

pub fn findWallpapers(self: *Self) !void {
    var datadirs_iter = std.mem.splitScalar(
        u8,
        std.posix.getenv("XDG_DATA_DIRS") orelse "",
        ':',
    );
    while (datadirs_iter.next()) |ddir| {
        var dirpath_buf: [std.fs.max_path_bytes]u8 = undefined;
        const dirpath = try std.fmt.bufPrintZ(&dirpath_buf, "{s}/backgrounds", .{ddir});

        var dir = std.fs.cwd().openDirZ(dirpath, .{ .iterate = true }) catch |e| switch (e) {
            error.FileNotFound => continue,
            else => return e,
        };
        defer dir.close();

        try self.walk(dir);
    }
}
