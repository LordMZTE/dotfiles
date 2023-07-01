const std = @import("std");

files: std.ArrayList([]u8),
filename_arena: std.heap.ArenaAllocator,

const Self = @This();

pub fn init(alloc: std.mem.Allocator) Self {
    return Self{
        .files = std.ArrayList([]u8).init(alloc),
        .filename_arena = std.heap.ArenaAllocator.init(alloc),
    };
}

pub fn deinit(self: *Self) void {
    self.filename_arena.deinit();
    self.files.deinit();
}

pub fn walk(self: *Self, dir: std.fs.IterableDir) anyerror!void {
    var iter = dir.iterate();
    while (try iter.next()) |e| {
        switch (e.kind) {
            .file => {
                const path = try dir.dir.realpathAlloc(self.filename_arena.allocator(), e.name);
                try self.files.append(path);
            },
            .directory => {
                var subdir = try dir.dir.openIterableDir(e.name, .{});
                defer subdir.close();
                try self.walk(subdir);
            },
            .sym_link => {
                var p_buf: [std.fs.MAX_PATH_BYTES]u8 = undefined;
                const p = try dir.dir.readLink(e.name, &p_buf);
                var subdir = dir.dir.openIterableDir(p, .{}) catch |err| {
                    switch (err) {
                        error.NotDir => {
                            const fpath = try self.filename_arena.allocator().dupe(u8, p);
                            try self.files.append(fpath);
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
