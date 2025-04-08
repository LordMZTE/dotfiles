const std = @import("std");

const Mutex = @import("mutex.zig").Mutex;

const log = std.log.scoped(.command);

pub const Command = struct {
    key: u8,
    label: []const u8,
    command: [][]const u8,
    exit: bool,

    pub fn deinit(self: Command, alloc: std.mem.Allocator) void {
        alloc.free(self.command);
    }

    pub fn run(
        self: Command,
        alloc: std.mem.Allocator,
        exit: *@import("util.zig").ExitMode,
        env: *Mutex(std.process.EnvMap),
    ) !void {
        if (std.mem.eql(u8, self.command[0], "!quit")) {
            exit.* = .delayed;
            log.info("user logged out", .{});
            return;
        }

        if (self.exit) exit.* = .immediate;

        log.info("run cmd: {s}", .{self.command});
        var child = std.process.Child.init(self.command, alloc);
        {
            env.mtx.lock();
            defer env.mtx.unlock();
            child.env_map = &env.data;
            try child.spawn();
        }
        _ = try child.wait();
    }
};

pub fn parseEntriesConfig(alloc: std.mem.Allocator, data: []const u8) ![]Command {
    var entries: std.ArrayListUnmanaged(Command) = .empty;
    errdefer entries.deinit(alloc);

    var line_splits = std.mem.tokenizeScalar(u8, data, '\n');
    while (line_splits.next()) |line| {
        const line_without_comment = std.mem.sliceTo(line, '#');
        if (line_without_comment.len == 0)
            continue;

        var seg_splits = std.mem.tokenizeScalar(u8, line_without_comment, ':');
        const labels = std.mem.trim(u8, seg_splits.next() orelse return error.InvalidConfig, &std.ascii.whitespace);
        const command = std.mem.trim(u8, seg_splits.next() orelse return error.InvalidConfig, &std.ascii.whitespace);
        var exit = false;
        if (seg_splits.next()) |extra| {
            if (std.mem.eql(u8, extra, "Q")) {
                exit = true;
            } else return error.InvalidConfig;
        }
        if (seg_splits.next()) |_| return error.InvalidConfig;

        if (labels.len < 3 or labels[1] != ' ') return error.InvalidConfig;
        const key = std.ascii.toUpper(labels[0]);
        const label = labels[2..];

        var argv: std.ArrayListUnmanaged([]const u8) = .empty;
        errdefer argv.deinit(alloc);
        var command_splits = std.mem.splitScalar(u8, command, ',');
        while (command_splits.next()) |arg|
            try argv.append(alloc, arg);

        if (argv.items.len == 0) return error.InvalidConfig;

        try entries.append(alloc, .{
            .key = key,
            .label = label,
            .command = try argv.toOwnedSlice(alloc),
            .exit = exit,
        });
    }

    return try entries.toOwnedSlice(alloc);
}
