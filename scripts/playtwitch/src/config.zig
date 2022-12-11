const std = @import("std");
const c = @import("ffi.zig").c;
const State = @import("State.zig");
const log = std.log.scoped(.config);

pub fn configLoaderThread(state: *State) !void {
    const home = std.os.getenv("HOME") orelse return error.HomeNotSet;
    const channels_path = try std.fs.path.join(
        std.heap.c_allocator,
        &.{ home, ".config", "playtwitch", "channels.cfg" },
    );
    defer std.heap.c_allocator.free(channels_path);

    log.info("reading config from '{s}'", .{channels_path});
    const start_time = std.time.milliTimestamp();

    const file = std.fs.cwd().openFile(channels_path, .{}) catch |e| {
        switch (e) {
            error.FileNotFound => {
                log.warn("channels config file not found at {s}, skipping.", .{channels_path});
                return;
            },
            else => return e,
        }
    };
    defer file.close();

    const channels_data = try file.readToEndAlloc(std.heap.c_allocator, std.math.maxInt(usize));
    var channels = std.ArrayList(State.Entry).init(std.heap.c_allocator);

    var channels_iter = std.mem.tokenize(u8, channels_data, "\n");
    while (channels_iter.next()) |line| {
        var line_iter = std.mem.tokenize(u8, line, ":");

        const channel = line_iter.next() orelse continue;
        const channel_trimmed = std.mem.trim(u8, channel, " \n\r");

        if (channel_trimmed.len <= 0 or channel_trimmed[0] == '#')
            continue;

        const comment_trimmed = blk: {
            const comment = line_iter.next() orelse break :blk null;

            var comment_trimmed = std.mem.trim(u8, comment, " \n\r");

            if (comment_trimmed.len == 0)
                break :blk null;

            break :blk comment_trimmed;
        };

        // dashes act as separator
        if (std.mem.allEqual(u8, channel_trimmed, '-')) {
            // separators can have comments to act as headings
            try channels.append(.{ .separator = comment_trimmed });

            continue;
        }

        try channels.append(.{ .channel = .{
            .name = channel_trimmed,
            .comment = comment_trimmed,
        } });
    }

    const end_time = std.time.milliTimestamp();

    log.info(
        "Loaded {d} channel items in {d}ms",
        .{ channels.items.len, end_time - start_time },
    );

    {
        state.mutex.lock();
        defer state.mutex.unlock();

        state.channels_file_data = channels_data;
        state.channels = try channels.toOwnedSlice();
    }

    @import("live.zig").tryFetchChannelsLive(state);
}
