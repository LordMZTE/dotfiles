const std = @import("std");
const State = @import("State.zig");
const c = @import("ffi.zig").c;
const log = std.log.scoped(.live);

pub fn reloadLiveThread(s: *State) !void {
    {
        s.mutex.lock();
        defer s.mutex.unlock();

        for (s.channels.?) |*chan| {
            switch (chan.*) {
                .channel => |*ch| ch.live = .loading,
                else => {},
            }
        }
    }

    try fetchChannelsLive(s);
}

pub fn fetchChannelsLive(s: *State) !void {
    @atomicStore(bool, &s.live_status_loading, true, .Unordered);
    defer @atomicStore(bool, &s.live_status_loading, false, .Unordered);
    log.info("initiaizing cURL", .{});
    var curl = c.curl_easy_init();
    if (curl == null)
        return error.CurlInitError;
    defer c.curl_easy_cleanup(curl);

    try handleCurlErr(c.curl_easy_setopt(
        curl,
        c.CURLOPT_WRITEFUNCTION,
        &curlWriteCb,
    ));
    try handleCurlErr(c.curl_easy_setopt(curl, c.CURLOPT_NOPROGRESS, @as(c_long, 1)));
    try handleCurlErr(c.curl_easy_setopt(curl, c.CURLOPT_FOLLOWLOCATION, @as(c_long, 1)));

    // the twitch info grabbinator works by downloading the web page
    // and checking if it contains a string. this is the bufffer for the page.
    //
    // Fuck you, twitch! amazing API design!
    var page_buf = std.ArrayList(u8).init(std.heap.c_allocator);
    defer page_buf.deinit();

    try handleCurlErr(c.curl_easy_setopt(curl, c.CURLOPT_WRITEDATA, &page_buf));

    // we shouldn't need to aquire the mutex here, this data isnt being read and we're
    // only doing atomic writes.
    var fmt_buf: [512]u8 = undefined;
    for (s.channels.?) |*entry| {
        const chan = if (entry.* == .channel) &entry.channel else continue;

        page_buf.clearRetainingCapacity();

        log.info("requesting live state for channel {s}", .{chan.name});

        const url = try std.fmt.bufPrintZ(
            &fmt_buf,
            "https://www.twitch.tv/{s}",
            .{chan.name},
        );
        try handleCurlErr(c.curl_easy_setopt(curl, c.CURLOPT_URL, url.ptr));
        try handleCurlErr(c.curl_easy_perform(curl));

        if (std.mem.containsAtLeast(u8, page_buf.items, 1, "live_user")) {
            @atomicStore(State.Live, &chan.live, .live, .Unordered);
        } else {
            @atomicStore(State.Live, &chan.live, .offline, .Unordered);
        }
    }
}

fn curlWriteCb(
    data: [*]const u8,
    size: usize,
    nmemb: usize,
    out: *std.ArrayList(u8),
) callconv(.C) usize {
    const realsize = size * nmemb;
    out.writer().writeAll(data[0..realsize]) catch return 0;
    return realsize;
}

fn handleCurlErr(code: c.CURLcode) !void {
    if (code != c.CURLE_OK) {
        log.err("Curl error: {s}", .{c.curl_easy_strerror(code)});
        return error.CurlError;
    }
}
