const std = @import("std");
const ffi = @import("ffi.zig");
const c = ffi.c;

const log = std.log.scoped(.clipboard);

dpy: *c.Display,
win: c.Window,

const ClipboardConnection = @This();

pub fn init() !ClipboardConnection {
    const dpy = c.XOpenDisplay(
        c.getenv("DISPLAY") orelse return error.DisplayNotSet,
    ) orelse return error.OpenDisplay;
    errdefer _ = c.XCloseDisplay(dpy);

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
    _ = c.XStoreName(dpy, win, "vinput");

    return .{
        .dpy = dpy,
        .win = win,
    };
}

pub fn deinit(self: *ClipboardConnection) void {
    _ = c.XDestroyWindow(self.dpy, self.win);
    _ = c.XCloseDisplay(self.dpy);
    self.* = undefined;
}

pub fn provide(self: ClipboardConnection, data: []const u8) !void {
    const selection = c.XInternAtom(self.dpy, "CLIPBOARD", 0);
    const targets_atom = c.XInternAtom(self.dpy, "TARGETS", 0);
    const text_atom = c.XInternAtom(self.dpy, "TEXT", 0);
    var utf8_atom = c.XInternAtom(self.dpy, "UTF8_STRING", 1);
    if (utf8_atom == c.None) {
        utf8_atom = c.XA_STRING;
    }

    _ = c.XSetSelectionOwner(self.dpy, selection, self.win, 0);
    if (c.XGetSelectionOwner(self.dpy, selection) != self.win) {
        return error.FailedToAquireSelection;
    }

    log.info("providing clipboard", .{});

    var event: c.XEvent = undefined;
    while (true) {
        try ffi.checkXError(self.dpy, c.XNextEvent(self.dpy, &event));
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
                        @ptrCast(&utf8_atom),
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
                        @intCast(data.len),
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
                        @intCast(data.len),
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

                    _ = c.XSendEvent(self.dpy, ev.requestor, 0, 0, @ptrCast(&ev));
                    if (sent_data) {
                        if (ffi.xGetWindowName(self.dpy, xsr.requestor)) |name| {
                            defer _ = c.XFree(name.ptr);

                            log.info("sent clipboard to {s}", .{name});
                        } else {
                            log.info("sent clipboard to unknown window", .{});
                        }
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

/// Get the current text in the clipboard. Must be freed using XFree.
pub fn getText(self: ClipboardConnection) !?[]u8 {
    log.info("reading clipboard", .{});
    const utf8 = c.XInternAtom(self.dpy, "UTF8_STRING", 0);
    if (try self.getContentForType(utf8)) |data| return data;

    return try self.getContentForType(c.XA_STRING);
}

fn getContentForType(self: ClipboardConnection, t: c.Atom) !?[]u8 {
    const selection = c.XInternAtom(self.dpy, "CLIPBOARD", 0);
    //const utf8_atom = c.XInternAtom(self.dpy, "UTF8_STRING", 1);
    const xsel_data_atom = c.XInternAtom(self.dpy, "XSEL_DATA", 0);

    _ = c.XConvertSelection(self.dpy, selection, t, xsel_data_atom, self.win, c.CurrentTime);
    _ = c.XSync(self.dpy, 0);

    var event: c.XEvent = undefined;
    try ffi.checkXError(self.dpy, c.XNextEvent(self.dpy, &event));

    if (event.type != c.SelectionNotify)
        return null;

    const xsel = event.xselection;

    // Wrong selection or conversion failed.
    if (xsel.property == 0)
        return null;

    var target: c.Atom = undefined;
    var data: ?[*]u8 = null;
    var format: c_int = 0;
    var size: c_ulong = 0;
    var n: c_ulong = 0;
    _ = c.XGetWindowProperty(
        xsel.display,
        xsel.requestor,
        xsel.property,
        0,
        -1,
        0,
        c.AnyPropertyType,
        &target,
        &format,
        &size,
        &n,
        &data,
    );
    defer _ = c.XDeleteProperty(xsel.display, xsel.requestor, xsel.property);

    return (data orelse return null)[0..@intCast(size)];
}
