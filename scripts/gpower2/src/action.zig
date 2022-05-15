const std = @import("std");

pub const Action = enum {
    Shutdown,
    Reboot,
    Suspend,
    Hibernate,

    pub fn execute(
        self: Action,
        handle_out: *?std.ChildProcess,
        alloc: std.mem.Allocator,
    ) !void {
        var argv: [2][]const u8 = undefined;
        argv[0] = "systemctl";

        argv[1] = switch (self) {
            .Shutdown => "poweroff",
            .Reboot => "reboot",
            .Suspend => "suspend",
            .Hibernate => "hibernate",
        };

        var child = std.ChildProcess.init(&argv, alloc);
        try child.spawn();
        handle_out.* = child;
    }
};
