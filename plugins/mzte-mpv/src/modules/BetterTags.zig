const std = @import("std");
const c = ffi.c;
const ansiterm = @import("ansi-term");

const ffi = @import("../ffi.zig");

const BetterTags = @This();

const log = std.log.scoped(.@"better-tags");

// Needed to silence error that we'd otherwise get because this thing being zero-sized would make it
// a comptime var or something.
_placeholder: u1 = 0,

pub fn create() BetterTags {
    return .{};
}

pub fn setup(self: *BetterTags, mpv: *c.mpv_handle) !void {
    _ = self;
    try ffi.checkMpvError(c.mpv_observe_property(
        mpv,
        0,
        "metadata",
        c.MPV_FORMAT_NODE,
    ));
}

pub fn onEvent(self: *BetterTags, mpv: *c.mpv_handle, ev: *c.mpv_event) !void {
    switch (ev.event_id) {
        c.MPV_EVENT_PROPERTY_CHANGE => {
            const evprop: *c.mpv_event_property = @ptrCast(@alignCast(ev.data));
            if (std.mem.orderZ(u8, evprop.name, "metadata") == .eq) {
                try self.onMetaChange(mpv);
            }
        },
        else => {},
    }
}

fn onMetaChange(self: *BetterTags, mpv: *c.mpv_handle) !void {
    _ = self;
    var meta_node: c.mpv_node = undefined;
    ffi.checkMpvError(c.mpv_get_property(
        mpv,
        "metadata",
        c.MPV_FORMAT_NODE,
        &meta_node,
    )) catch |e| switch (e) {
        // happens one time on startup for whatever reason
        error.PropertyUnavailable => return,
        else => return e,
    };
    defer c.mpv_free_node_contents(&meta_node);
    std.debug.assert(meta_node.format == c.MPV_FORMAT_NODE_MAP);

    var title: ?[]const u8 = null;
    var description: ?[]const u8 = null;
    var other_fields: std.StringArrayHashMapUnmanaged([]const u8) = .empty;
    defer other_fields.deinit(std.heap.c_allocator);

    var i: usize = 0;
    while (meta_node.u.list.*.keys[i] != null) : (i += 1) {
        const val_node = meta_node.u.list.*.values[i];
        if (val_node.format != c.MPV_FORMAT_STRING) continue;

        const key = std.mem.span(meta_node.u.list.*.keys[i]);
        const value = std.mem.span(val_node.u.string);

        if (std.ascii.eqlIgnoreCase(key, "title")) {
            title = value;
        } else if (std.ascii.eqlIgnoreCase(key, "description") or std.ascii.eqlIgnoreCase(key, "ytdl_description")) {
            description = value;
        } else if (std.mem.indexOfScalar(u8, value, '\n') == null) {
            // Don't print other multiline properties
            try other_fields.put(std.heap.c_allocator, key, value);
        }
    }

    if (title == null) {
        // fall back to getting title from `media-title`
        var media_title_cstr: [*:0]const u8 = undefined;
        try ffi.checkMpvError(c.mpv_get_property(
            mpv,
            "media-title",
            c.MPV_FORMAT_STRING,
            @ptrCast(&media_title_cstr),
        ));

        title = std.mem.span(media_title_cstr);
    }

    var out_buf = std.io.bufferedWriter(std.io.getStdOut().writer());
    const out = out_buf.writer();

    const textwidth = 100;

    const sep_thick = "━";
    const sep_thin = "─";

    const sepwidth = @min(textwidth, @max(
        multilineStringWidth(title orelse ""),
        multilineStringWidth(description orelse ""),
    ));

    const sepstyle = ansiterm.style.Style{ .foreground = .Magenta };
    const titlestyle = ansiterm.style.Style{ .foreground = .Blue, .font_style = .{ .bold = true } };
    const keystyle = ansiterm.style.Style{ .foreground = .Yellow, .font_style = .{ .bold = true } };
    const valstyle = ansiterm.style.Style{ .foreground = .Green };

    if (title != null or description != null) {
        try ansiterm.format.updateStyle(out, sepstyle, null);
        try out.writeBytesNTimes(sep_thick, sepwidth);
        try out.writeByte('\n');

        if (title) |t| {
            try ansiterm.format.updateStyle(out, titlestyle, sepstyle);
            try out.writeAll(t);
            try out.writeByte('\n');

            try ansiterm.format.updateStyle(out, sepstyle, titlestyle);
            try out.writeBytesNTimes(if (description != null) sep_thin else sep_thick, sepwidth);
            try out.writeByte('\n');
        }

        if (description) |d| {
            try ansiterm.format.resetStyle(out);

            write_desc: {
                // write description with rudimentary hard wrapping
                var char_iter = (std.unicode.Utf8View.init(d) catch {
                    log.warn("Description is invalid UTF8, skipping", .{});
                    break :write_desc;
                }).iterator();
                var linelen: usize = 0;
                while (char_iter.nextCodepointSlice()) |cp| {
                    try out.writeAll(cp);

                    if (cp.len == 1 and cp[0] == '\n') {
                        linelen = 0;
                        continue;
                    }

                    linelen += 1;

                    if (linelen >= textwidth) {
                        try out.writeByte('\n');
                        linelen = 0;
                    }
                }

                try out.writeByte('\n');
            }

            try ansiterm.format.updateStyle(out, sepstyle, null);
            try out.writeBytesNTimes(sep_thick, sepwidth);
            try out.writeByte('\n');
        }
    }

    var iter = other_fields.iterator();
    while (iter.next()) |kv| {
        try ansiterm.format.updateStyle(out, keystyle, valstyle);
        try out.writeAll(kv.key_ptr.*);
        try out.writeAll(": ");

        try ansiterm.format.updateStyle(out, valstyle, keystyle);
        try out.writeAll(kv.value_ptr.*);
        try out.writeByte('\n');
    }

    try ansiterm.format.resetStyle(out);
    try out_buf.flush();
}

fn multilineStringWidth(str: []const u8) usize {
    var len: usize = 0;

    var iter = std.mem.tokenizeScalar(u8, str, '\n');
    while (iter.next()) |line| {
        // This is obviously not correct as this isn't glyph count, but good enough.
        len = @max(len, line.len);
    }

    return len;
}

pub fn deinit(self: *BetterTags) void {
    _ = self;
}
