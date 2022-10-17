const std = @import("std");
const ffi = @import("ffi.zig");
const c = ffi.c;

const log = std.log.scoped(.clipboard);

/// Provides the given data to the X clipboard ONCE
pub fn provideClipboard(data: []const u8, alloc: std.mem.Allocator) !void {
    _ = alloc;
    const dpy = c.XOpenDisplay(
        c.getenv("DISPLAY") orelse return error.DisplayNotSet,
    ) orelse return error.OpenDisplay;
    defer _ = c.XCloseDisplay(dpy);

    const screen_n = c.XDefaultScreen(dpy);
    const screen = c.XScreenOfDisplay(dpy, screen_n);
    const win = c.XCreateSimpleWindow(
        dpy,
        screen.*.root,
        0,
        0,
        1,
        1,
        0,
        screen.*.black_pixel,
        screen.*.white_pixel,
    );

    const selection = c.XInternAtom(dpy, "CLIPBOARD", 0);
    const targets_atom = c.XInternAtom(dpy, "TARGETS", 0);
    const text_atom = c.XInternAtom(dpy, "TEXT", 0);
    var utf8_atom = c.XInternAtom(dpy, "UTF8_STRING", 1);
    if (utf8_atom == c.None) {
        utf8_atom = c.XA_STRING;
    }

    _ = c.XSetSelectionOwner(dpy, selection, win, 0);
    if (c.XGetSelectionOwner(dpy, selection) != win) {
        return error.FailedToAquireSelection;
    }

    log.info("providing clipboard", .{});

    var event: c.XEvent = undefined;
    while (true) {
        try ffi.checkXError(dpy, c.XNextEvent(dpy, &event));
        switch (event.type) {
            c.SelectionRequest => {
                if (event.xselectionrequest.selection != selection)
                    continue;

                const xsr = event.xselectionrequest;

                var sent_data = false;
                var r: c_int = 0;
                if (xsr.target == targets_atom) {
                    r = c.XChangeProperty(
                        xsr.display,
                        xsr.requestor,
                        xsr.property,
                        c.XA_ATOM,
                        32,
                        c.PropModeReplace,
                        @ptrCast([*c]u8, &utf8_atom),
                        1,
                    );
                } else if (xsr.target == c.XA_STRING or xsr.target == text_atom) {
                    r = c.XChangeProperty(
                        xsr.display,
                        xsr.requestor,
                        xsr.property,
                        c.XA_STRING,
                        8,
                        c.PropModeReplace,
                        data.ptr,
                        @intCast(c_int, data.len),
                    );
                    sent_data = true;
                } else if (xsr.target == utf8_atom) {
                    r = c.XChangeProperty(
                        xsr.display,
                        xsr.requestor,
                        xsr.property,
                        utf8_atom,
                        8,
                        c.PropModeReplace,
                        data.ptr,
                        @intCast(c_int, data.len),
                    );
                    sent_data = true;
                }

                if ((r & 2) == 0) {
                    var ev = c.XSelectionEvent{
                        .type = c.SelectionNotify,
                        .display = xsr.display,
                        .requestor = xsr.requestor,
                        .selection = xsr.selection,
                        .time = xsr.time,
                        .target = xsr.target,
                        .property = xsr.property,

                        .serial = 0,
                        .send_event = 0,
                    };

                    _ = c.XSendEvent(dpy, ev.requestor, 0, 0, @ptrCast(*c.XEvent, &ev));
                    if (sent_data) {
                        var real: c.Atom = undefined;
                        var format: c_int = 0;
                        var n: c_ulong = 0;
                        var extra: c_ulong = 0;
                        var name_cstr: [*c]u8 = undefined;
                        _ = c.XGetWindowProperty(
                            dpy,
                            xsr.requestor,
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
                        if (name_cstr != null) {
                            defer _ = c.XFree(name_cstr);

                            const name = std.mem.span(name_cstr);

                            log.info("sent clipboard to {s}", .{name});
                        } else {
                            log.info("sent clipboard to unknown window", .{});
                        }
                        break;
                    }
                }
            },
            c.SelectionClear => {
                log.info("Selection cleared", .{});
                break;
            },
            else => {},
        }
    }
}
