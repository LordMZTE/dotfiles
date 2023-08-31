const std = @import("std");

const Monitor = struct {
    width: u32,
    height: u32,
    x: u32,
    y: u32,
};

const Window = struct {
    address: []const u8,
    floating: bool,
    size: [2]u32,
};

pub fn doFullerscreen(alloc: std.mem.Allocator, sockpath: []const u8) !void {
    var json_arena = std.heap.ArenaAllocator.init(alloc);
    defer json_arena.deinit();

    const parsed = request: {
        const stream = try std.net.connectUnixSocket(sockpath);
        defer stream.close();

        try stream.writeAll("[[BATCH]][-j]/monitors;[-j]/activewindow;");
        var json_reader = std.json.reader(json_arena.allocator(), stream.reader());

        const json_options = std.json.ParseOptions{
            .ignore_unknown_fields = true,
            .max_value_len = std.json.default_max_value_len,
            .allocate = .alloc_if_needed,
        };

        const monitors = try std.json.innerParse(
            []Monitor,
            json_arena.allocator(),
            &json_reader,
            json_options,
        );

        json_reader.scanner.state = .value;

        const active_window = try std.json.innerParse(
            Window,
            json_arena.allocator(),
            &json_reader,
            json_options,
        );

        break :request .{ .monitors = monitors, .active_window = active_window };
    };

    var bottom_right_monitor: ?Monitor = null;
    for (parsed.monitors) |mon| {
        if (bottom_right_monitor == null or
            mon.x > bottom_right_monitor.?.x or
            mon.y > bottom_right_monitor.?.y)
            bottom_right_monitor = mon;
    }

    std.debug.assert(bottom_right_monitor != null);

    std.log.info("active window address: {s}", .{parsed.active_window.address});

    const new_width = bottom_right_monitor.?.x + bottom_right_monitor.?.width;
    const new_height = bottom_right_monitor.?.y + bottom_right_monitor.?.height;
    std.log.info("new window size: {}x{}", .{ new_width, new_height });

    const stream = try std.net.connectUnixSocket(sockpath);
    defer stream.close();

    var buf_writer = std.io.bufferedWriter(stream.writer());
    const writer = buf_writer.writer();

    try writer.writeAll("[[BATCH]]");

    // window is already fullerscreen
    if (parsed.active_window.floating and
        parsed.active_window.size[0] == new_width and
        parsed.active_window.size[1] == new_height)
    {
        std.log.info("already fullerscreen, tiling window", .{});
        // disable floating
        try writer.print("/dispatch togglefloating address:{s};", .{parsed.active_window.address});
    } else {
        // ensure window is floating
        if (!parsed.active_window.floating) {
            try writer.print("/dispatch togglefloating address:{s};", .{parsed.active_window.address});
        }

        // set pos to 0/0
        try writer.print(
            "/dispatch movewindowpixel exact 0 0,address:{s};",
            .{parsed.active_window.address},
        );

        // resize
        try writer.print(
            "/dispatch resizewindowpixel exact {} {},address:{s};",
            .{ new_width, new_height, parsed.active_window.address },
        );
    }

    try buf_writer.flush();

    var fifo = std.fifo.LinearFifo(u8, .{ .Static = 1024 * 4 }).init();
    try fifo.pump(stream.reader(), std.io.getStdOut().writer());
}
