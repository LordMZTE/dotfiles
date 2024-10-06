const std = @import("std");
const ziggy = @import("ziggy");

ignored_scripts: []const []const u8 = &.{},

const Options = @This();

pub fn parseConfig(arena: std.mem.Allocator) !Options {
    const opts_path = try std.fs.path.join(arena, &.{
        std.posix.getenv("HOME") orelse return error.NoHome,
        ".config/mzte_localconf/setup-opts.ziggy",
    });
    if (std.fs.cwd().readFileAllocOptions(
        arena,
        opts_path,
        1024 * 1024,
        null,
        @alignOf(u8),
        0,
    )) |opts_data| {
        var diag: ziggy.Diagnostic = .{ .path = opts_path };
        return ziggy.parseLeaky(Options, arena, opts_data, .{
            .diagnostic = &diag,
            .copy_strings = .to_unescape,
        }) catch |e| {
            std.log.err("failed to parse opts:\n{}", .{diag});
            return e;
        };
    } else |e| {
        std.log.warn("Couldn't read options: {}", .{e});
        return .{};
    }
}

pub fn isBlacklisted(self: Options, script: []const u8) bool {
    for (self.ignored_scripts) |s| {
        if (std.mem.eql(u8, s, script)) return true;
    }

    return false;
}
