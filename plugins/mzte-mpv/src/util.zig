const std = @import("std");
const c = ffi.c;

const ffi = @import("ffi.zig");

pub fn msg(
    mpv: *c.mpv_handle,
    scope: @TypeOf(.enum_tag),
    comptime fmt: []const u8,
    args: anytype,
) !void {
    std.log.scoped(scope).info(fmt, args);

    var buf: [1024 * 4]u8 = undefined;
    const osd_msg = try std.fmt.bufPrintZ(&buf, "[mzte-mpv " ++ @tagName(scope) ++ "] " ++ fmt, args);
    try ffi.checkMpvError(c.mpv_command(
        mpv,
        @constCast(&[_:null]?[*:0]const u8{ "show-text", osd_msg, "4000" }),
    ));
}
