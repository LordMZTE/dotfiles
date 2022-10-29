const std = @import("std");
const c = @import("ffi.zig").c;
const State = @import("State.zig");

pub fn configLoaderThread(state: *State) !void {
    const home = std.os.getenv("HOME") orelse return error.HomeNotSet;
    const channels_path = try std.fs.path.join(
        std.heap.c_allocator,
        &.{ home, ".config", "playtwitch", "channels" },
    );
    defer std.heap.c_allocator.free(channels_path);

    const file = std.fs.cwd().openFile(channels_path, .{}) catch |e| {
        switch (e) {
            error.FileNotFound => {
                std.log.warn("Channels config file not found at {s}, skipping.", .{channels_path});
                return;
            },
            else => return e,
        }
    };
    defer file.close();

    const channels_data = try file.readToEndAlloc(std.heap.c_allocator, std.math.maxInt(usize));
    var channels = std.ArrayList([]const u8).init(std.heap.c_allocator);

    var channels_iter = std.mem.split(u8, channels_data, "\n");
    while (channels_iter.next()) |channel| {
        const trimmed = std.mem.trim(u8, channel, " \n\r");
        if (trimmed.len > 0)
            try channels.append(trimmed);
    }

    state.mutex.lock();
    defer state.mutex.unlock();

    state.channels_file_data = channels_data;
    state.channels = channels.toOwnedSlice();
}
