const std = @import("std");
const log = std.log.scoped(.ffi);

pub const c = @cImport({
    @cInclude("stdlib.h");
    @cInclude("X11/Xlib.h");
    @cInclude("X11/Xatom.h");
});

pub fn checkXError(dpy: *c.Display, code: c_int) !void {
    if (code == 0)
        return;

    var buf: [512]u8 = undefined;

    if (c.XGetErrorText(dpy, code, &buf, buf.len) != 0) {
        return error.FailedToGetErrorText;
    }

    log.err("X: {s}", .{buf});
    return error.XError;
}
