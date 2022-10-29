const std = @import("std");
const c = @import("ffi.zig").c;
const config = @import("config.zig");

mutex: std.Thread.Mutex,
win: *c.GLFWwindow,

/// start chatty if true
chatty: bool,
chatty_alive: bool,

/// an array of channels, composed of slices into `channels_file_data`
channels: ?[][]const u8,

/// the data of the channels configuration file
channels_file_data: ?[]u8,

quality_buf: [64]u8,
channel_name_buf: [64]u8,

streamlink_memfd: ?std.fs.File,
streamlink_out: ?[]align(std.mem.page_size) u8,

const Self = @This();

pub fn init(win: *c.GLFWwindow) !*Self {
    // on the heap so this thing doesn't move.
    const self = try std.heap.c_allocator.create(Self);
    self.* = .{
        .mutex = .{},
        .win = win,

        .chatty = true,
        .chatty_alive = false,

        // initialized by config loader thread
        .channels = null,
        .channels_file_data = null,

        .quality_buf = std.mem.zeroes([64]u8),
        .channel_name_buf = std.mem.zeroes([64]u8),

        .streamlink_memfd = null,
        .streamlink_out = null,
    };

    std.mem.copy(u8, &self.quality_buf, "best");

    const thread = try std.Thread.spawn(.{}, config.configLoaderThread, .{self});
    thread.detach();

    return self;
}

pub fn freeStreamlinkMemfd(self: *Self) void {
    if (self.streamlink_out) |mem| {
        std.os.munmap(mem);
        self.streamlink_out = null;
    }

    if (self.streamlink_memfd) |fd| {
        fd.close();
        self.streamlink_memfd = null;
    }
}

pub fn deinit(self: *Self) void {
    self.freeStreamlinkMemfd();

    if (self.channels) |ch| {
        std.heap.c_allocator.free(ch);
    }

    if (self.channels_file_data) |d| {
        std.heap.c_allocator.free(d);
    }

    self.* = undefined;
}
