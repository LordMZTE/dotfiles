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

pub fn walk(self: *Self, io: std.Io, dir: std.Io.Dir) anyerror!void {
    var iter = dir.iterate();
    while (try iter.next(io)) |e| {
        switch (e.kind) {
            .file => {
                var rpath_buf: [std.fs.max_path_bytes]u8 = undefined;
                const path = try self.filename_arena.allocator().dupeZ(
                    u8,
                    rpath_buf[0..try dir.realPathFile(io, e.name, &rpath_buf)],
                );
                try self.files.append(self.alloc, path);
            },
            .directory => {
                var subdir = try dir.openDir(io, e.name, .{ .iterate = true });
                defer subdir.close(io);
                try self.walk(io, subdir);
            },
            .sym_link => {
                var p_buf: [std.fs.max_path_bytes]u8 = undefined;
                const p = p_buf[0..try dir.readLink(io, e.name, &p_buf)];
                var subdir = dir.openDir(io, p, .{ .iterate = true }) catch |err| {
                    switch (err) {
                        error.NotDir => {
                            const fpath = try self.filename_arena.allocator().dupeZ(u8, p);
                            try self.files.append(self.alloc, fpath);
                            continue;
                        },
                        else => return err,
                    }
                };
                defer subdir.close(io);

                try self.walk(io, subdir);
            },
            else => {},
        }
    }
}

pub fn findWallpapers(self: *Self, io: std.Io, env: *std.process.Environ.Map) !void {
    var datadirs_iter = std.mem.splitScalar(
        u8,
        env.get("XDG_DATA_DIRS") orelse "",
        ':',
    );
    while (datadirs_iter.next()) |ddir| {
        var dirpath_buf: [std.fs.max_path_bytes]u8 = undefined;
        const dirpath = try std.fmt.bufPrint(&dirpath_buf, "{s}/backgrounds", .{ddir});

        var dir = std.Io.Dir.cwd().openDir(io, dirpath, .{ .iterate = true }) catch |e| switch (e) {
            error.FileNotFound => continue,
            else => return e,
        };
        defer dir.close(io);

        try self.walk(io, dir);
    }
}
