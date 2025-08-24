const std = @import("std");
const at = @import("ansi-term");

pub const ansi_clear = "\x1b[2J\x1b[1;1H";

pub const ExitMode = enum { run, immediate, delayed };

pub inline fn updateStyle(writer: *std.Io.Writer, current: *?at.style.Style, new: at.style.Style) !void {
    try at.format.updateStyle(writer, new, current.*);
    current.* = new;
}

pub fn findInPath(alloc: std.mem.Allocator, path: []const u8, bin: []const u8) !?[]const u8 {
    var splits = std.mem.splitScalar(u8, path, ':');
    while (splits.next()) |p| {
        const trimmed = std.mem.trim(u8, p, " \n\r");
        if (trimmed.len == 0)
            continue;

        const joined = try std.fs.path.join(
            alloc,
            &.{ trimmed, bin },
        );

        _ = std.fs.cwd().statFile(joined) catch |e| {
            alloc.free(joined);
            switch (e) {
                error.FileNotFound, error.AccessDenied => continue,
                else => return e,
            }
        };

        return joined;
    }
    return null;
}
