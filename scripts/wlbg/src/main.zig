const std = @import("std");

const proto = @import("proto.zig");

const State = @import("State.zig");

pub const std_options = std.Options{
    .log_level = .debug,
    .logFn = @import("common").logFn,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const wl_dpy_name = std.posix.getenv("WAYLAND_DISPLAY") orelse return error.NoDisplay;
    const xdgrtdir = std.posix.getenv("XDG_RUNTIME_DIR") orelse return error.NoRuntimeDir;

    var sockpath_buf: [std.fs.max_path_bytes]u8 = undefined;
    const sockpath = try std.fmt.bufPrintZ(&sockpath_buf, "{s}/swww-{s}.sock", .{ xdgrtdir, wl_dpy_name });

    var wp_arena = std.heap.ArenaAllocator.init(alloc);
    defer wp_arena.deinit();

    var walker = @import("Walker.zig").init(alloc);
    defer walker.deinit();
    try walker.findWallpapers();

    std.log.info("found {} wallpapers", .{walker.files.items.len});
    if (walker.files.items.len == 0) return error.NoWallpapers;

    var state = State{
        .alloc = alloc,
        .wps = walker.files.items,
        .rand = std.Random.DefaultPrng.init(std.crypto.random.int(u64)),
        .sockpath = sockpath,
    };

    // Don't spawn daemon if the socket exists, one must already be running.
    var swww_daemon = if (std.fs.cwd().statFile(sockpath)) |_|
        null
    else |_|
        std.process.Child.init(&.{"swww-daemon"}, alloc);
    if (swww_daemon) |*d| try d.spawn();

    defer if (swww_daemon) |*d| {
        _ = d.kill() catch |e| std.log.err("could not kill swww-daemon: {}", .{e});
    };

    const epfd = try std.posix.epoll_create1(0);
    defer std.posix.close(epfd);

    const sigset = comptime sigs: {
        var sigs = std.posix.empty_sigset;
        std.os.linux.sigaddset(&sigs, std.os.linux.SIG.INT);
        std.os.linux.sigaddset(&sigs, std.os.linux.SIG.TERM);
        std.os.linux.sigaddset(&sigs, std.os.linux.SIG.CHLD);
        std.os.linux.sigaddset(&sigs, std.os.linux.SIG.USR1);
        std.os.linux.sigaddset(&sigs, std.os.linux.SIG.USR2);
        break :sigs sigs;
    };
    std.posix.sigprocmask(std.posix.SIG.BLOCK, &sigset, null);

    const sigfd = try std.posix.signalfd(-1, &sigset, 0);
    defer std.posix.close(sigfd);

    var sigfdev = std.os.linux.epoll_event{
        .events = std.os.linux.EPOLL.IN,
        .data = .{ .fd = sigfd },
    };

    try std.posix.epoll_ctl(epfd, std.os.linux.EPOLL.CTL_ADD, sigfd, &sigfdev);

    const refresh_tfd = try std.posix.timerfd_create(.MONOTONIC, .{});
    defer std.posix.close(refresh_tfd);

    try resetRefreshTime(refresh_tfd);

    var refresh_tfdev = std.os.linux.epoll_event{
        .events = std.os.linux.EPOLL.IN,
        .data = .{ .fd = refresh_tfd },
    };

    try std.posix.epoll_ctl(epfd, std.os.linux.EPOLL.CTL_ADD, refresh_tfd, &refresh_tfdev);

    var mode = proto.WallpaperMode.random;

    while (true) {
        var evbuf: [32]std.os.linux.epoll_event = undefined;
        const evs = evbuf[0..std.posix.epoll_wait(epfd, &evbuf, -1)];

        for (evs) |ev| {
            if (ev.data.fd == sigfd) {
                var siginf: std.os.linux.signalfd_siginfo = undefined;
                std.debug.assert(try std.posix.read(sigfd, std.mem.asBytes(&siginf)) == @sizeOf(std.os.linux.signalfd_siginfo));

                if (siginf.signo == std.os.linux.SIG.USR1) {
                    if (mode == .random)
                        try proto.randomizeWallpapers(&state, .random);
                } else if (siginf.signo == std.os.linux.SIG.USR2) {
                    mode = switch (mode) {
                        .random => .dark,
                        .dark => .random,
                    };
                    if (mode == .dark)
                        try proto.randomizeWallpapers(&state, .dark)
                    else
                        try resetRefreshTime(refresh_tfd);
                } else {
                    std.log.info("got signal {}, exiting", .{siginf.signo});
                    return;
                }
            } else if (ev.data.fd == refresh_tfd) {
                var tfd_buf: [@sizeOf(usize)]u8 = undefined;
                std.debug.assert(try std.posix.read(refresh_tfd, &tfd_buf) == tfd_buf.len);
                if (mode == .random)
                    proto.randomizeWallpapers(&state, .random) catch |e|
                        std.log.warn("chaning wallpapers: {}", .{e});
            }
        }
    }
}

fn resetRefreshTime(tfd: std.os.linux.fd_t) !void {
    try std.posix.timerfd_settime(tfd, .{}, &.{
        .it_value = .{ .sec = 1, .nsec = 0 },
        .it_interval = .{
            .sec = std.time.s_per_min * 5, // refresh every 5 minutes
            .nsec = 0,
        },
    }, null);
}
