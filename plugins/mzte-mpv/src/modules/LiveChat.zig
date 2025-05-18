//! This module will find .live_chat.json files from yt-dlp and transcode them to WEBVTT, which
//! is then transferred to mpv via a pipe.
//! The live_chat file must be next to the video being viewed.
const std = @import("std");
const c = ffi.c;

const ffi = @import("../ffi.zig");
const util = @import("../util.zig");

const log = std.log.scoped(.@"live-chat");

// Zig segfaults when this is a ZST
padding: u1 = 0,

const LiveChat = @This();

pub fn onEvent(self: *LiveChat, mpv: *c.mpv_handle, ev: *c.mpv_event) !void {
    _ = self;
    switch (ev.event_id) {
        c.MPV_EVENT_PROPERTY_CHANGE => {
            const evprop: *c.mpv_event_property = @ptrCast(@alignCast(ev.data));
            if (std.mem.eql(u8, std.mem.span(evprop.name), "path")) {
                var buf: [std.fs.max_path_bytes]u8 = undefined;

                const str = std.mem.span((@as(?*[*:0]const u8, @ptrCast(@alignCast(evprop.data))) orelse return).*);

                // Don't check live_chat for non-file streams
                if (!util.pathIsRegularFile(str)) return;
                const fname = fname: {
                    const dot_idx = std.mem.lastIndexOfScalar(u8, str, '.') orelse return;
                    break :fname try std.fmt.bufPrintZ(&buf, "{s}.live_chat.json", .{str[0..dot_idx]});
                };
                const file = std.fs.cwd().openFileZ(fname, .{}) catch |e| switch (e) {
                    error.FileNotFound => return,
                    else => return e,
                };
                errdefer file.close();
                log.info("initializing subtitle transcoder: {s}", .{fname});

                const pipe = try std.posix.pipe2(.{});

                // This needs to be done here instead of the separate thread. MPV will instantly
                // give up if there's nothing to be read from the pipe when the command is called.
                try (std.fs.File{ .handle = pipe[1] }).writer().writeAll(
                    \\WEBVTT - MZTE-MPV transcoded live stream chat
                    \\
                    \\00:00.000 --> 00:05.000
                    \\[MZTE-MPV] Live chat subtitle transcoder initialized
                    \\
                    \\
                );

                const sub_addr = try std.fmt.bufPrintZ(&buf, "fdclose://{}", .{pipe[0]});
                try ffi.checkMpvError(c.mpv_command_async(
                    mpv,
                    0,
                    @constCast(&[_:null]?[*]const u8{ "sub-add", sub_addr.ptr, "select", "MZTE-MPV live chat" }),
                ));

                // Quite stupidly, MPV will wait until the WHOLE subtitle stream is received before
                // adding the track. We still do this in a separate thread so we don't have to
                // buffer the WEBVTT data and MPV can concurrently decode it.
                (try std.Thread.spawn(.{}, transcoderThread, .{ file, pipe[1] })).detach();
            }
        },
        else => {},
    }
}

fn transcoderThread(jsonf: std.fs.File, pipefd: std.c.fd_t) !void {
    defer jsonf.close();
    var pipe = std.fs.File{ .handle = pipefd };
    defer pipe.close();

    var writer = std.io.bufferedWriter(pipe.writer());

    try writer.flush();

    var reader = std.io.bufferedReader(jsonf.reader());
    var line_buf: std.ArrayListUnmanaged(u8) = .empty;
    defer line_buf.deinit(std.heap.c_allocator);

    while (true) {
        line_buf.clearRetainingCapacity();
        reader.reader().streamUntilDelimiter(line_buf.writer(std.heap.c_allocator), '\n', null) catch |e| switch (e) {
            error.EndOfStream => break,
            else => return e,
        };
        processLine(line_buf.items, pipe.writer()) catch |e| {
            log.warn("failed to parse chat entry: {}", .{e});
        };
    }

    try writer.flush();
}

/// I have yet to find who is responsible for this but oh boy...
const ChatEntry = struct {
    replayChatItemAction: struct {
        actions: []struct {
            addChatItemAction: struct {
                item: struct {
                    liveChatTextMessageRenderer: struct {
                        message: struct {
                            runs: []struct {
                                text: ?[]u8 = null,
                            },
                        },
                        authorName: struct {
                            simpleText: []u8,
                        },
                    },
                },
            },
        },
        videoOffsetTimeMsec: usize,
    },
};

const WebVttTime = struct {
    ms: usize,

    pub fn format(
        self: WebVttTime,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        const time: @Vector(4, usize) = @splat(self.ms);
        const div: @Vector(4, usize) = .{ std.time.ms_per_hour, std.time.ms_per_min, std.time.ms_per_s, 1 };
        const mod: @Vector(4, usize) = .{ 1, 60, 60, 1000 };
        const times = @divTrunc(time, div) % mod;

        try writer.print("{d:0>2}:{d:0>2}:{d:0>2}.{d:0>3}", .{ times[0], times[1], times[2], times[3] });
    }
};

fn processLine(line: []const u8, pipe: anytype) !void {
    const parsed = try std.json.parseFromSlice(
        ChatEntry,
        std.heap.c_allocator,
        line,
        .{ .ignore_unknown_fields = true },
    );
    defer parsed.deinit();

    // Show chat messages for 5 seconds
    const ms = parsed.value.replayChatItemAction.videoOffsetTimeMsec;
    try pipe.print("{} --> {}\n", .{ WebVttTime{ .ms = ms }, WebVttTime{ .ms = ms + 5000 } });

    for (parsed.value.replayChatItemAction.actions) |act| {
        try pipe.print("<b>&lt;{s}&gt;:</b> ", .{
            act.addChatItemAction.item.liveChatTextMessageRenderer.authorName.simpleText,
        });
        for (act.addChatItemAction.item.liveChatTextMessageRenderer.message.runs) |seg| {
            if (seg.text) |txt| {
                std.mem.replaceScalar(u8, txt, '\n', '\\');
                try pipe.writeAll(txt);
            } else {
                // Emojis and such
                try pipe.writeAll("&lt;?&gt;");
            }
        }
        try pipe.writeByte('\n');
    }
    try pipe.writeByte('\n');
}

pub fn create() LiveChat {
    return .{};
}

pub fn setup(self: *LiveChat, mpv: *c.mpv_handle) !void {
    _ = self;
    try ffi.checkMpvError(c.mpv_observe_property(mpv, 0, "path", c.MPV_FORMAT_STRING));
}

pub fn deinit(self: *LiveChat) void {
    _ = self;
}
