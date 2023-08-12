const std = @import("std");
const c = @import("ffi.zig").c;

pub fn getHeadCount() !u32 {
    const connection = c.xcb_connect(null, null).?;
    if (c.xcb_connection_has_error(connection) > 0) return error.ConnectionFailed;
    defer c.xcb_disconnect(connection);

    var err: ?*c.xcb_generic_error_t = null;

    const is_active_cookie = c.xcb_xinerama_is_active(connection);
    const is_active_reply = c.xcb_xinerama_is_active_reply(connection, is_active_cookie, &err);
    if (err) |_| return error.FailedToQueryXinerama;
    defer std.c.free(is_active_reply);
    if (is_active_reply.*.state == 0) return error.XineramaInactive;

    const query_screens_cookie = c.xcb_xinerama_query_screens(connection);
    const query_screens_reply = c.xcb_xinerama_query_screens_reply(connection, query_screens_cookie, &err);
    if (err) |_| return error.FailedToQueryXinerama;
    defer std.c.free(query_screens_reply);

    return query_screens_reply.*.number;
}
