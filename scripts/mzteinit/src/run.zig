const std = @import("std");
const log = std.log.scoped(.run);

pub const Command = enum {
    startx,
    shell,
    zellij,
    logout,
    shutdown,
    reboot,

    pub fn fromChar(c: u8) ?Command {
        return switch (c) {
            'x', 'X' => .startx,
            's', 'S' => .shell,
            'z', 'Z' => .zellij,
            'l', 'L' => .logout,
            'p', 'P' => .shutdown,
            'r', 'R' => .reboot,
            else => null,
        };
    }

    pub fn char(self: Command) u8 {
        return switch (self) {
            .startx => 'X',
            .shell => 'S',
            .zellij => 'Z',
            .logout => 'L',
            .shutdown => 'P',
            .reboot => 'R',
        };
    }

    pub fn run(
        self: Command,
        alloc: std.mem.Allocator,
        exit: *@import("util.zig").ExitMode,
        env: *const std.process.EnvMap,
    ) !void {
        switch (self) {
            .logout => {
                exit.* = .delayed;
                log.info("user logged out", .{});
                return;
            },
            .shutdown, .reboot => exit.* = .immediate,
            else => {},
        }

        const arg = self.argv();
        log.info("run cmd: {s}", .{arg});
        var child = std.ChildProcess.init(arg, alloc);
        child.env_map = env;
        _ = try child.spawnAndWait();
    }

    fn argv(self: Command) []const []const u8 {
        return switch (self) {
            .startx => &.{"startx"},
            .shell => &.{"fish"},
            .zellij => &.{"zellij"},
            .logout => unreachable,
            .shutdown => &.{ "systemctl", "poweroff" },
            .reboot => &.{ "systemctl", "reboot" },
        };
    }
};
