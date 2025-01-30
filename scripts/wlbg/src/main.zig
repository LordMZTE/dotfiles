const std = @import("std");
const wayland = @import("wayland");
const wl = wayland.client.wl;
const xdg = wayland.client.zxdg;

const Output = @import("Output.zig");
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

    const dpy = try wl.Display.connect(wl_dpy_name);
    defer dpy.disconnect();

    var state = State{
        .wps = walker.files.items,
        .outputs = std.ArrayList(*Output).init(alloc),
        .rand = std.Random.DefaultPrng.init(std.crypto.random.int(u64)),
        .sockpath = sockpath,
    };
    defer {
        for (state.outputs.items) |outp| {
            outp.deinit();
        }
        state.outputs.deinit();
    }

    const reg = try dpy.getRegistry();
    defer reg.destroy();
    reg.setListener(*State, &registryListener, &state);

    var swww_daemon = std.process.Child.init(&.{"swww-daemon"}, alloc);
    try swww_daemon.spawn();

    defer _ = swww_daemon.kill() catch |e| std.log.err("could not kill swww-daemon: {}", .{e});

    const epfd = try std.posix.epoll_create1(0);
    defer std.posix.close(epfd);

    const sigset = comptime sigs: {
        var sigs = std.posix.empty_sigset;
        std.os.linux.sigaddset(&sigs, std.os.linux.SIG.INT);
        std.os.linux.sigaddset(&sigs, std.os.linux.SIG.TERM);
        std.os.linux.sigaddset(&sigs, std.os.linux.SIG.CHLD);
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

    var wlfdev = std.os.linux.epoll_event{
        .events = std.os.linux.EPOLL.IN,
        .data = .{ .fd = dpy.getFd() },
    };

    try std.posix.epoll_ctl(epfd, std.os.linux.EPOLL.CTL_ADD, dpy.getFd(), &wlfdev);

    if (dpy.flush() != .SUCCESS)
        return error.WaylandDispatch;
    std.debug.assert(dpy.prepareRead());

    const refresh_tfd = try std.posix.timerfd_create(std.posix.CLOCK.MONOTONIC, .{});
    defer std.posix.close(refresh_tfd);

    try std.posix.timerfd_settime(refresh_tfd, .{}, &.{
        .it_value = .{ .tv_sec = 1, .tv_nsec = 0 },
        .it_interval = .{
            .tv_sec = std.time.s_per_min * 5, // refresh every 5 minutes
            .tv_nsec = 0,
        },
    }, null);

    var refresh_tfdev = std.os.linux.epoll_event{
        .events = std.os.linux.EPOLL.IN,
        .data = .{ .fd = refresh_tfd },
    };

    try std.posix.epoll_ctl(epfd, std.os.linux.EPOLL.CTL_ADD, refresh_tfd, &refresh_tfdev);

    while (true) {
        var evbuf: [32]std.os.linux.epoll_event = undefined;
        const evs = evbuf[0..std.posix.epoll_wait(epfd, &evbuf, -1)];

        for (evs) |ev| {
            if (ev.data.fd == sigfd) {
                var siginf: std.os.linux.signalfd_siginfo = undefined;
                std.debug.assert(try std.posix.read(sigfd, std.mem.asBytes(&siginf)) == @sizeOf(std.os.linux.signalfd_siginfo));
                std.log.info("got signal {}, exiting", .{siginf.signo});

                return;
            } else if (ev.data.fd == dpy.getFd()) {
                if (dpy.readEvents() != .SUCCESS)
                    return error.WaylandDispatch;

                while (!dpy.prepareRead())
                    if (dpy.dispatchPending() != .SUCCESS or dpy.flush() != .SUCCESS)
                        return error.WaylandDispatch;
            } else if (ev.data.fd == refresh_tfd) {
                var tfd_buf: [@sizeOf(usize)]u8 = undefined;
                std.debug.assert(try std.posix.read(refresh_tfd, &tfd_buf) == tfd_buf.len);
                try @import("proto.zig").randomizeWallpapers(&state);
            }
        }
    }
}

fn registryListener(reg: *wl.Registry, ev: wl.Registry.Event, state: *State) void {
    switch (ev) {
        .global => |glob| {
            if (std.mem.orderZ(u8, glob.interface, wl.Output.interface.name) == .eq) {
                std.log.info("binding output with ID {}", .{glob.name});
                state.outputs.append(Output.init(
                    state.outputs.allocator,
                    reg.bind(
                        glob.name,
                        wl.Output,
                        wl.Output.generated_version,
                    ) catch return,
                    glob.name,
                ) catch @panic("OOM")) catch @panic("OOM");
            }
        },
        .global_remove => |glob| {
            for (state.outputs.items, 0..) |outp, i| {
                std.log.debug("{}, {}", .{ outp.output.getId(), glob.name });
                if (glob.name == outp.id) {
                    std.log.info("removing output with ID {}", .{glob.name});
                    state.outputs.orderedRemove(i).deinit();
                }
            }
        },
    }
}
