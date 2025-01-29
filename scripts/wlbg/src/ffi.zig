const std = @import("std");

pub const c = @cImport({
    @cInclude("gdk-pixbuf/gdk-pixbuf.h");
});

pub fn checkGError(err: ?*c.GError) !void {
    if (err) |e| {
        std.log.err("GLib error: {s}", .{e.message});
        return error.GError;
    }
}
