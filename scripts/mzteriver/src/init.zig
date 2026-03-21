const std = @import("std");
const cgopts = @import("cgopts");

fn initCommand(comptime argv: []const [:0]const u8) []const [:0]const u8 {
    return &[_][:0]const u8{
        "systemd-cat",
        "--level-prefix=false",
        "--identifier=" ++ argv[0],
        "--",
    } ++ argv;
}

pub fn init(alloc: std.mem.Allocator) !void {
    std.log.info("spawning processes", .{});

    var child_arena = std.heap.ArenaAllocator.init(alloc);
    defer child_arena.deinit();

    // spawn initialization processes
    for ([_][]const []const u8{
        &.{
            "dbus-update-activation-environment",
            "DISPLAY",
            "XAUTHORITY",
            "WAYLAND_DISPLAY",
            "XDG_CURRENT_DESKTOP",
        },
        &.{
            "systemctl",
            "--user",
            "import-environment",
            "DISPLAY",
            "XAUTHORITY",
            "WAYLAND_DISPLAY",
            "XDG_CURRENT_DESKTOP",
        },
    }) |argv| {
        var child = std.process.Child.init(argv, child_arena.allocator());
        try child.spawn();

        _ = try child.wait();
    }

    var mzterwm_child = std.process.Child.init(&.{"mzterwm"}, child_arena.allocator());
    try mzterwm_child.spawn();

    inline for (cgopts.startup_commands) |argv| {
        var child = std.process.Child.init(initCommand(&argv), child_arena.allocator());
        try child.spawn();

        // TODO: this is a resource leak if we don't wait. We should use the as of yet
        // non-existant `detach`-API instead.
    }
}
