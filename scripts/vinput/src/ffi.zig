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

/// Result must be freed using XFree
pub fn xGetWindowName(dpy: *c.Display, win: c.Window) ?[]u8 {
    var real: c.Atom = undefined;
    var format: c_int = 0;
    var n: c_ulong = 0;
    var extra: c_ulong = 0;
    var name_cstr: [*c]u8 = undefined;
    _ = c.XGetWindowProperty(
        dpy,
        win,
        c.XA_WM_NAME,
        0,
        ~@as(c_int, 0),
        0,
        c.AnyPropertyType,
        &real,
        &format,
        &n,
        &extra,
        &name_cstr,
    );

    if (name_cstr == null)
        return null;

    return name_cstr[0..@intCast(n)];
}
