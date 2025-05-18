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
        @constCast(&[_:null]?[*]const u8{ "show-text", osd_msg.ptr, "4000" }),
    ));
}

/// Returns true if the given path, as stored in the `path` property points to a regular file.
pub fn pathIsRegularFile(path: []const u8) bool {
    return !std.mem.containsAtLeast(u8, path, 1, "://") and
        path[path.len - 1] != '-'; // stdin is reported as /some/path/-
}
