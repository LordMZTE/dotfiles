const std = @import("std");
const c = @import("ffi.zig").c;

pub fn getHeadCount() !i32 {
    const display_name = c.getenv("DISPLAY") orelse return error.DisplayNotSet;
    const display = c.XOpenDisplay(display_name) orelse return error.CouldntOpenDisplay;

    defer _ = c.XCloseDisplay(display);

    if (c.XineramaIsActive(display) == 0) {
        return error.XineramaError;
    }

    var screens: c_int = 0;
    const info = c.XineramaQueryScreens(display, &screens) orelse return error.XineramaError;
    defer _ = c.XFree(info);

    return screens;
}
