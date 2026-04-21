const std = @import("std");
const common = @import("common");
const cg = @import("cg");

const river_init = @import("init.zig");

pub const std_options = std.Options{
    .logFn = @import("common").logFn,
};

pub const mztecommon_opts = common.Opts{
    .log_pfx = "mzteriver-classic",
};

pub fn main(init: std.process.Init) !void {
    const alloc = init.gpa;
    const argv = init.minimal.args.vector;

    var init_future: ?std.Io.Future(river_init.StartupCommandsError!void) = null;
    defer if (init_future) |*f| f.await(init.io) catch {};

    const home = init.environ_map.get("HOME") orelse return error.HomeNotSet;

    if (std.mem.endsWith(u8, std.mem.span(argv[0]), "init") or
        (argv.len >= 2 and std.mem.orderZ(u8, argv[1], "init") == .eq))
    {
        std.log.info("running in init mode", .{});
        init_future = try river_init.init(alloc, init.io, true, home);
    } else if (std.mem.endsWith(u8, std.mem.span(argv[0]), "reinit") or
        (argv.len >= 2 and std.mem.orderZ(u8, argv[1], "reinit") == .eq))
    {
        std.log.info("running in reinit mode", .{});
        init_future = try river_init.init(alloc, init.io, false, home);
    } else {
        std.log.info("running in launch mode", .{});

        const logfd = logf: {
            var logf_pathbuf: [std.fs.max_path_bytes]u8 = undefined;
            const logf_path = try std.fmt.bufPrintZ(
                &logf_pathbuf,
                "/tmp/mzteriver-classic-{}-{}.log",
                .{ std.os.linux.getuid(), std.os.linux.getpid() },
            );

            std.log.info("river-classic log file: {s}", .{logf_path});

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

        var conffile_buf: [std.fs.max_path_bytes]u8 = undefined;
        const conffile = try std.fmt.bufPrintZ(
            &conffile_buf,
            "{s}/.config/river-classic/init",
            .{home},
        );

        return std.process.replace(init.io, .{
            .argv = &.{ "river-classic", "-c", conffile },
        });
    }
}
