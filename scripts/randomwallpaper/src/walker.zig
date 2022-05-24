const std = @import("std");

pub const Walker = struct {
    files: std.ArrayList([]u8),
    filename_arena: std.heap.ArenaAllocator,
    buf: [64]u8 = undefined,

    pub const open_opts = std.fs.Dir.OpenDirOptions{ .iterate = true };

    pub fn init(alloc: std.mem.Allocator) Walker {
        return Walker{
            .files = std.ArrayList([]u8).init(alloc),
            .filename_arena = std.heap.ArenaAllocator.init(alloc),
        };
    }

    pub fn deinit(self: *Walker) void {
        self.filename_arena.deinit();
        self.files.deinit();
    }

    pub fn walk(self: *Walker, dir: std.fs.Dir) anyerror!void {
        var iter = dir.iterate();
        while (try iter.next()) |e| {
            switch (e.kind) {
                .File => {
                    const path = try dir.realpathAlloc(self.filename_arena.allocator(), e.name);
                    try self.files.append(path);
                },
                .Directory => {
                    var subdir = try dir.openDir(e.name, open_opts);
                    defer subdir.close();
                    try self.walk(subdir);
                },
                .SymLink => {
                    const p = try dir.readLink(e.name, &self.buf);
                    var subdir = dir.openDir(p, open_opts) catch |err| {
                        switch (err) {
                            std.fs.Dir.OpenError.NotDir => {
                                const fpath = try self.filename_arena.allocator().dupe(u8, p);
                                try self.files.append(fpath);
                                continue;
                            },
                            else => {
                                return err;
                            },
                        }
                    };
                    defer subdir.close();

                    try self.walk(subdir);
                },
                else => {},
            }
        }
    }
};
