const std = @import("std");
const ziggy = @import("ziggy").ziggy;

ignored_scripts: []const []const u8 = &.{},

const Options = @This();

pub fn parseConfig(arena: std.mem.Allocator, io: std.Io, home: []const u8) !Options {
    const opts_path = try std.fs.path.join(arena, &.{
        home,
        ".config/mzte_localconf/setup-opts.ziggy",
    });
    if (std.Io.Dir.cwd().readFileAllocOptions(
        io,
        opts_path,
        arena,
        .limited(1024 * 1024),
        .of(u8),
        0,
    )) |opts_data| {
        var meta: ziggy.Deserializer.Meta = .init;
        return ziggy.deserializeLeaky(Options, arena, opts_data, &meta, .{}) catch |e| {
            std.log.err("failed to parse opts:\n{}", .{e});
            var stderr_buf: [512]u8 = undefined;
            const stderr = std.debug.lockStderr(&stderr_buf);
            defer std.debug.unlockStderr();
            meta.reportErrors(
                arena,
                .{},
                opts_path,
                opts_data,
                e,
                &stderr.file_writer.interface,
            ) catch |e_| {
                std.log.err("failed to report opts parse error: {}", .{e_});
            };
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
