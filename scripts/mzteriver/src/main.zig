const std = @import("std");
const common = @import("common");
const opts = @import("opts");

const init = @import("init.zig").init;

pub const std_options = std.Options{
    .log_level = switch (@import("builtin").mode) {
        .Debug => .debug,
        else => .info,
    },
    .logFn = @import("common").logFn,
};

pub const mztecommon_opts = common.Opts{
    .log_pfx = "mzteriver",
};

pub fn main() !void {
    var dbg_gpa = if (@import("builtin").mode == .Debug) std.heap.GeneralPurposeAllocator(.{}){} else {};
    defer if (@TypeOf(dbg_gpa) != void) {
        _ = dbg_gpa.deinit();
    };
    const alloc = if (@TypeOf(dbg_gpa) == void) std.heap.c_allocator else dbg_gpa.allocator();

    if (std.mem.endsWith(u8, std.mem.span(std.os.argv[0]), "init") or
        (std.os.argv.len >= 2 and std.mem.orderZ(u8, std.os.argv[1], "init") == .eq))
    {
        std.log.info("running in init mode", .{});
        try init(alloc, true);
    } else if (std.mem.endsWith(u8, std.mem.span(std.os.argv[0]), "reinit") or
        (std.os.argv.len >= 2 and std.mem.orderZ(u8, std.os.argv[1], "reinit") == .eq))
    {
        std.log.info("running in reinit mode", .{});
        try init(alloc, false);
    } else {
        std.log.info("running in launch mode", .{});

        const logfd = logf: {
            const logf_path = try std.fmt.allocPrintZ(
                alloc,
                "/tmp/mzteriver-{}-{}.log",
                .{ std.os.linux.getuid(), std.os.linux.getpid() },
            );
            defer alloc.free(logf_path);

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
            errdefer std.posix.close(logfd);

            // redirect river's STDERR and STDOUT to log file
            try std.posix.dup2(logfd, std.posix.STDOUT_FILENO);
            try std.posix.dup2(logfd, std.posix.STDERR_FILENO);
        }
        std.posix.close(logfd);

        var env = std.BoundedArray(?[*:0]const u8, 0xff).init(0) catch unreachable;
        const envp: [*:null]?[*:0]const u8 = env: {
            try env.appendSlice(std.os.environ);

            try env.append("XKB_DEFAULT_LAYOUT=de");
            try env.append("QT_QPA_PLATFORM=wayland");
            try env.append("XDG_CURRENT_DESKTOP=river");

            if (opts.cg.nvidia) {
                try env.append("WLR_NO_HARDWARE_CURSORS=1");
            }

            // manually add sentinel
            try env.append(null);
            break :env @ptrCast(env.slice().ptr);
        };

        return std.posix.execvpeZ("river", &[_:null]?[*:0]const u8{"river"}, envp);
    }
}
