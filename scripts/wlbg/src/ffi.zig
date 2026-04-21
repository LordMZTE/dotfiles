const std = @import("std");
const c = @import("c");

pub fn checkGError(err: ?*c.GError) !void {
    if (err) |e| {
        std.log.err("GLib error: {s}", .{e.message});
        return error.GError;
    }
}
