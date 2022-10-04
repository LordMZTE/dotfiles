const std = @import("std");

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

    pub fn run(self: Command, exit: *bool) !void {
        if (self == .logout) {
            exit.* = true;
            return;
        }

        var mem: [512]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&mem);
        const arg = self.argv();
        var child = std.ChildProcess.init(arg, fba.allocator());
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