const std = @import("std");
const opts = @import("opts");

pub const std_options = struct {
    pub const log_level = switch (@import("builtin").mode) {
        .Debug => .debug,
        else => .info,
    };
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    if (std.mem.endsWith(u8, std.mem.span(std.os.argv[0]), "init") or
        (std.os.argv.len >= 2 and std.mem.orderZ(u8, std.os.argv[1], "init") == .eq))
    {
        std.log.info("running in init mode", .{});
        try @import("init.zig").init(alloc);
    } else {
        std.log.info("running in launch mode", .{});

        const envp = env: {
            var env = try std.ArrayList(?[*:0]const u8)
                .initCapacity(alloc, std.os.environ.len + 16);
            errdefer env.deinit();
            try env.appendSlice(std.os.environ);

            try env.append("XKB_DEFAULT_LAYOUT=de");
            try env.append("QT_QPA_PLATFORM=wayland");
            try env.append("XDG_CURRENT_DESKTOP=river");

            if (opts.nvidia) {
                try env.append("WLR_NO_HARDWARE_CURSORS=1");
            }

            break :env try env.toOwnedSliceSentinel(null);
        };

        // techncially unreachable
        defer alloc.free(envp);

        return std.os.execvpeZ("river", &[_:null]?[*:0]const u8{"river"}, envp);
    }
}
