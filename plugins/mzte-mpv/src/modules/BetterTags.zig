const std = @import("std");
const c = ffi.c;
const ansiterm = @import("ansi-term");

const ffi = @import("../ffi.zig");

const BetterTags = @This();

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

        const key = meta_node.u.list.*.keys[i];
        const value = std.mem.span(val_node.u.string);

        if (std.mem.orderZ(u8, key, "TITLE") == .eq) {
            title = value;
        } else if (std.mem.orderZ(u8, key, "DESCRIPTION") == .eq) {
            description = value;
        } else if (std.mem.indexOfScalar(u8, value, '\n') == null) {
            // Don't print other multiline properties
            try other_fields.put(std.heap.c_allocator, std.mem.span(key), value);
        }
    }

    var out_buf = std.io.bufferedWriter(std.io.getStdOut().writer());
    const out = out_buf.writer();

    const sep_thick = "━";
    const sep_thin = "─";

    const sepwidth = @min(100, @max(
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
            try out.writeAll(d);
            try out.writeByte('\n');

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
