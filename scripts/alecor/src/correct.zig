const std = @import("std");

const util = @import("util.zig");

/// Commands which are prioritized for correction
const priority_commands = [_][]const u8{
    "git",
};

/// Commands which wrap another
const wrapper_commands = std.ComptimeStringMap(void, .{
    .{ "doas", {} },
    .{ "sudo", {} },
    .{ "rbg", {} },
    .{ "rbgd", {} },
    .{ "pkexec", {} },
});

fn populateArgMap(map: *ArgMap) !void {
    try map.put(&.{"git"}, .{ .subcommand = &.{ "push", "pull", "reset", "checkout" } });
    try map.put(&.{ "git", "checkout" }, .file_or_directory);
}

const ArgRequirement = union(enum) {
    subcommand: []const []const u8,
    file,
    directory,
    file_or_directory,
};

const ArgMap = std.HashMap(
    []const []const u8,
    ArgRequirement,
    struct {
        pub fn hash(self: @This(), v: []const []const u8) u64 {
            _ = self;
            var hasher = std.hash.Wyhash.init(0);
            hasher.update(std.mem.asBytes(&v.len));
            for (v) |s| {
                hasher.update(std.mem.asBytes(&v.len));
                hasher.update(s);
            }

            return hasher.final();
        }

        pub fn eql(self: @This(), a: []const []const u8, b: []const []const u8) bool {
            _ = self;
            if (a.len != b.len)
                return false;

            for (a, b) |va, vb|
                if (!std.mem.eql(u8, va, vb))
                    return false;

            return true;
        }
    },
    std.hash_map.default_max_load_percentage,
);

pub fn correctCommand(
    arena: *std.heap.ArenaAllocator,
    /// Command to correct in-place
    cmd: [][]const u8,
    /// Set of all valid commands
    commands: *std.StringHashMap(void),
) !void {
    const alloc = arena.child_allocator;

    var subslice = cmd;

    // skip wrapper commands
    while (subslice.len > 0 and wrapper_commands.has(subslice[0]))
        subslice = subslice[1..];

    // empty command
    if (subslice.len == 0)
        return;

    if (!commands.contains(subslice[0])) {
        // correct command
        var best: ?struct { []const u8, usize } = null;

        // do priority commands first and sub 1 from distance
        for (priority_commands) |possible_cmd| {
            const dist = try util.dist(alloc, subslice[0], possible_cmd) -| 1; // prioritize by subtracting 1
            if (best == null or best.?.@"1" > dist)
                best = .{ possible_cmd, dist };
        }

        if (best != null and best.?.@"1" != 0) {
            var iter = commands.keyIterator();
            while (iter.next()) |possible_cmd| {
                const dist = try util.dist(alloc, subslice[0], possible_cmd.*);
                if (best == null or best.?.@"1" > dist)
                    best = .{ possible_cmd.*, dist };
            }
        }

        if (best) |b| {
            if (!std.mem.eql(u8, subslice[0], b.@"0")) {
                std.log.info("[C] {s} => {s}", .{ subslice[0], b.@"0" });
                subslice[0] = b.@"0";
            }
        }
    }

    if (subslice.len < 2)
        return;

    var arg_map = ArgMap.init(alloc);
    defer arg_map.deinit();
    try populateArgMap(&arg_map);

    // correct args. loop as long as corrections are made
    while (true) {
        var req: ?ArgRequirement = null;

        var cmd_slice_end = subslice.len - 1;

        while (cmd_slice_end >= 1) : (cmd_slice_end -= 1) {
            if (arg_map.get(subslice[0..cmd_slice_end])) |r| {
                req = r;
                cmd_slice_end -= 1;
                break;
            }
        }

        // If the argument contains a slash, assume it's a path.
        if (req == null and std.mem.containsAtLeast(u8, subslice[cmd_slice_end + 1], 1, "/"))
            req = .file_or_directory;

        if (req) |r| {
            var new_arg = subslice[cmd_slice_end + 1];
            try correctArgForReq(arena, r, &new_arg);
            if (!std.mem.eql(u8, subslice[cmd_slice_end + 1], new_arg)) {
                std.log.info("[A] {s} => {s}", .{ subslice[cmd_slice_end + 1], new_arg });
                subslice[cmd_slice_end + 1] = new_arg;
            } else break;
        } else break;
    }
}

fn correctArgForReq(arena: *std.heap.ArenaAllocator, req: ArgRequirement, arg: *[]const u8) !void {
    const alloc = arena.child_allocator;
    switch (req) {
        .subcommand => |subcmds| {
            var best: ?struct { []const u8, usize } = null;
            for (subcmds) |possible_cmd| {
                const dist = try util.dist(alloc, arg.*, possible_cmd);
                if (best == null or best.?.@"1" > dist)
                    best = .{ possible_cmd, dist };
            }

            if (best) |b|
                arg.* = b.@"0";
        },
        .file, .directory, .file_or_directory => {
            if (arg.len == 0)
                return;

            var path_spliter = std.mem.tokenize(u8, arg.*, "/");
            var path_splits = std.ArrayList([]const u8).init(alloc);
            defer path_splits.deinit();

            // path is absolute
            if (arg.*[0] == '/')
                try path_splits.append("/");

            while (path_spliter.next()) |split| {
                if (std.mem.eql(u8, split, "~")) {
                    try path_splits.append(std.os.getenv("HOME") orelse return error.HomeNotSet);
                } else {
                    try path_splits.append(split);
                }
            }

            for (path_splits.items, 0..) |*split, cur_idx| {
                const dirs = path_splits.items[0..cur_idx];
                const dir_subpath = try std.fs.path.join(arena.allocator(), if (dirs.len == 0) &.{"."} else dirs);

                var iterable_dir = try std.fs.cwd().openIterableDir(dir_subpath, .{});
                defer iterable_dir.close();

                // if the given file already exists, there's no point in iterating the dir
                if (iterable_dir.dir.statFile(split.*)) |_| continue else |e| switch (e) {
                    error.FileNotFound => {},
                    else => return e,
                }

                var best: ?struct { []const u8, usize } = null;

                var dir_iter = iterable_dir.iterate();

                var best_buf: [1024]u8 = undefined;

                while (try dir_iter.next()) |entry| {
                    switch (req) {
                        .file => if (entry.kind == .directory) continue,
                        .directory => if (entry.kind != .directory and
                            entry.kind != .sym_link) continue,
                        else => {},
                    }

                    const dist = try util.dist(alloc, split.*, entry.name);
                    if (best == null or best.?.@"1" > dist) {
                        if (entry.name.len > best_buf.len)
                            return error.OutOfMemory;
                        const buf_slice = best_buf[0..entry.name.len];
                        @memcpy(buf_slice, entry.name);
                        best = .{ buf_slice, dist };
                    }
                }

                if (best) |b| {
                    split.* = try arena.allocator().dupe(u8, b.@"0");
                } else break;
            }

            arg.* = try std.fs.path.join(arena.allocator(), path_splits.items);
        },
    }
}
