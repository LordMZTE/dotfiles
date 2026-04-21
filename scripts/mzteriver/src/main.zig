const std = @import("std");
const common = @import("common");
const cg = @import("cg");

const river_init = @import("init.zig");

pub const std_options = std.Options{
    .logFn = @import("common").logFn,
};

pub const mztecommon_opts = common.Opts{
    .log_pfx = "mzteriver",
};

pub fn main(init: std.process.Init) !void {
    const alloc = init.gpa;
    const argv = init.minimal.args.vector;

    var init_future: ?std.Io.Future(river_init.StartupCommandsError!void) = null;
    defer if (init_future) |*f| f.await(init.io) catch {};

    if (std.mem.endsWith(u8, std.mem.span(argv[0]), "init") or
        (argv.len >= 2 and std.mem.orderZ(u8, argv[1], "init") == .eq))
    {
        std.log.info("running in init mode", .{});
        const home = init.environ_map.get("HOME") orelse return error.HomeNotSet;
        init_future = try river_init.init(alloc, init.io, home);
    } else {
        std.log.info("running in launch mode", .{});

        const logfd = logf: {
            var logf_pathbuf: [std.fs.max_path_bytes]u8 = undefined;
            const logf_path = try std.fmt.bufPrintZ(
                &logf_pathbuf,
                "/tmp/mzteriver-{}-{}.log",
                .{ std.os.linux.getuid(), std.os.linux.getpid() },
            );

            std.log.info("river log file: {s}", .{logf_path});

            break :logf try std.posix.openatZ(
                std.posix.AT.FDCWD,
                logf_path.ptr,
                // no CLOEXEC
                .{
                    .ACCMODE = .WRONLY,
                    .CREAT = true,
                    .TRUNC = true,
                },
                0o644,
            );
        };
        {
            errdefer _ = std.posix.system.close(logfd);

            // redirect river's STDERR and STDOUT to log file
            // What these functions are doing in std.Io.Threaded (and line-by-line copies of them in
            // other Io implementations) is anyone's guess.
            try std.Io.Threaded.dup2(logfd, std.posix.STDOUT_FILENO);
            try std.Io.Threaded.dup2(logfd, std.posix.STDERR_FILENO);
        }
        _ = std.posix.system.close(logfd);

        try init.environ_map.put("XKB_DEFAULT_LAYOUT", "de");
        try init.environ_map.put("QT_QPA_PLATFORM", "wayland");
        try init.environ_map.put("XDG_CURRENT_DESKTOP", "river");
        if (cg.nvidia) {
            try init.environ_map.put("WLR_NO_HARDWARE_CURSORS", "1");
        }

        return std.process.replace(
            init.io,
            .{ .argv = &.{"river"}, .environ_map = init.environ_map },
        );
    }
}
