const std = @import("std");
const builtin = @import("builtin");
const posix = @import("common").posix;

const proto = @import("proto.zig");

const State = @import("State.zig");

pub const std_options = std.Options{
    .log_level = .debug,
    .logFn = @import("common").logFn,
};

pub fn main(init: std.process.Init) !void {
    const wl_dpy_name = init.environ_map.get("WAYLAND_DISPLAY") orelse return error.NoDisplay;
    const xdgrtdir = init.environ_map.get("XDG_RUNTIME_DIR") orelse return error.NoRuntimeDir;

    var sockpath_buf: [std.fs.max_path_bytes]u8 = undefined;
    const sockpath = try std.fmt.bufPrintZ(
        &sockpath_buf,
        "{s}/{s}-awww-daemon.sock",
        .{ xdgrtdir, wl_dpy_name },
    );

    var walker = @import("Walker.zig").init(init.gpa);
    defer walker.deinit();
    try walker.findWallpapers(init.io, init.environ_map);

    std.log.info("found {} wallpapers", .{walker.files.items.len});
    if (walker.files.items.len == 0) return error.NoWallpapers;

    // randomSecure is actually faster in our case because Io.Threaded's random function will create
    // it's own RNG instance and initialize it with randomSecure, wheras randomSecure uses a syscall
    // or libc.
    var rand_seed: u64 = undefined;
    try init.io.randomSecure(std.mem.asBytes(&rand_seed));

    var state = State{
        .alloc = init.gpa,
        .wps = walker.files.items,
        .rand = std.Random.DefaultPrng.init(rand_seed),
        .sockpath = sockpath,
    };

    // Don't spawn daemon if the socket exists, one must already be running.
    var awww_daemon = if (std.Io.Dir.cwd().statFile(init.io, sockpath, .{})) |_|
        null
    else |_|
        try std.process.spawn(init.io, .{ .argv = &.{"awww-daemon"} });

    defer if (awww_daemon) |*d| d.kill(init.io);

    const epfd: posix.EPoll = try .init();
    defer epfd.deinit();

    const sigset = sigs: {
        var sigs = std.posix.sigemptyset();
        std.posix.sigaddset(&sigs, std.os.linux.SIG.INT);
        std.posix.sigaddset(&sigs, std.os.linux.SIG.TERM);
        std.posix.sigaddset(&sigs, std.os.linux.SIG.CHLD);
        std.posix.sigaddset(&sigs, std.os.linux.SIG.USR1);
        std.posix.sigaddset(&sigs, std.os.linux.SIG.USR2);
        break :sigs sigs;
    };
    std.posix.sigprocmask(std.posix.SIG.BLOCK, &sigset, null);

    const sigfd = try std.posix.signalfd(-1, &sigset, 0);
    defer _ = std.posix.system.close(sigfd);

    try epfd.addFd(sigfd, std.os.linux.EPOLL.IN);

    const refresh_tfd: posix.TimerFd = try .init(.MONOTONIC, 0);
    defer refresh_tfd.deinit();

    try resetRefreshTime(refresh_tfd);

    try epfd.addFd(refresh_tfd.handle, std.os.linux.EPOLL.IN);

    var mode = proto.WallpaperMode.random;

    while (true) {
        var evbuf: [32]std.os.linux.epoll_event = undefined;
        const evs = try epfd.wait(&evbuf, -1);

        for (evs) |ev| {
            if (ev.data.fd == sigfd) {
                var siginf: std.os.linux.signalfd_siginfo = undefined;
                std.debug.assert(try std.posix.read(sigfd, std.mem.asBytes(&siginf)) == @sizeOf(std.os.linux.signalfd_siginfo));

                if (siginf.signo == @intFromEnum(std.os.linux.SIG.USR1)) {
                    if (mode == .random)
                        try proto.randomizeWallpapers(init.io, &state, .random);
                } else if (siginf.signo == @intFromEnum(std.os.linux.SIG.USR2)) {
                    mode = switch (mode) {
                        .random => .dark,
                        .dark => .random,
                    };
                    if (mode == .dark)
                        try proto.randomizeWallpapers(init.io, &state, .dark)
                    else
                        try resetRefreshTime(refresh_tfd);
                } else {
                    std.log.info("got signal {}, exiting", .{siginf.signo});
                    return;
                }
            } else if (ev.data.fd == refresh_tfd.handle) {
                var tfd_buf: [@sizeOf(usize)]u8 = undefined;
                std.debug.assert(try std.posix.read(refresh_tfd.handle, &tfd_buf) == tfd_buf.len);
                if (mode == .random)
                    proto.randomizeWallpapers(init.io, &state, .random) catch |e|
                        std.log.warn("changing wallpapers: {}", .{e});
            }
        }
    }
}

fn resetRefreshTime(tfd: posix.TimerFd) !void {
    try tfd.setTime(
        .{ .sec = 1, .nsec = 0 },
        .{
            .sec = std.time.s_per_min * 5, // refresh every 5 minutes
            .nsec = 0,
        },
    );
}
