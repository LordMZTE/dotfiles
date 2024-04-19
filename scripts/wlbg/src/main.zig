const std = @import("std");
const wayland = @import("wayland");

const c = @import("ffi.zig").c;
const options = @import("options.zig");

const DrawTimerHandler = @import("DrawTimerHandler.zig");
const Gfx = @import("Gfx.zig");
const Globals = @import("Globals.zig");
const OutputInfo = @import("OutputInfo.zig");
const OutputWindow = @import("OutputWindow.zig");
const PointerState = @import("PointerState.zig");

const wl = wayland.client.wl;
const zwlr = wayland.client.zwlr;
const zxdg = wayland.client.zxdg;

pub const std_options = std.Options{
    .log_level = .debug,
    .logFn = @import("common").logFn,
};

pub fn main() !void {
    std.log.info("connecting to wayland display", .{});
    const dpy = try wl.Display.connect(null);
    defer dpy.disconnect();
    const globs = try Globals.collect(dpy);
    defer globs.outputs.deinit();

    const output_info = try std.heap.c_allocator.alloc(OutputInfo, globs.outputs.items.len);
    defer std.heap.c_allocator.free(output_info);
    @memset(output_info, .{});

    for (globs.outputs.items, 0..) |output, i| {
        const xdg_output = try globs.xdg_output_manager.getXdgOutput(output);
        xdg_output.setListener(*OutputInfo, xdgOutputListener, &output_info[i]);
    }

    if (dpy.roundtrip() != .SUCCESS) return error.RoundtipFail;

    if (c.eglBindAPI(c.EGL_OPENGL_API) == 0) return error.EGLError;

    const egl_dpy = c.eglGetDisplay(@ptrCast(dpy)) orelse return error.EGLError;
    if (c.eglInitialize(egl_dpy, null, null) != c.EGL_TRUE) return error.EGLError;
    defer _ = c.eglTerminate(egl_dpy);

    const config = egl_conf: {
        var config: c.EGLConfig = undefined;
        var n_config: i32 = 0;
        if (c.eglChooseConfig(
            egl_dpy,
            &[_]i32{
                c.EGL_SURFACE_TYPE,    c.EGL_WINDOW_BIT,
                c.EGL_RENDERABLE_TYPE, c.EGL_OPENGL_BIT,
                c.EGL_RED_SIZE,        8,
                c.EGL_GREEN_SIZE,      8,
                c.EGL_BLUE_SIZE,       8,
                c.EGL_NONE,
            },
            &config,
            1,
            &n_config,
        ) != c.EGL_TRUE) return error.EGLError;
        break :egl_conf config;
    };

    std.log.info("creating EGL context", .{});
    const egl_ctx = c.eglCreateContext(
        egl_dpy,
        config,
        c.EGL_NO_CONTEXT,
        &[_]i32{
            c.EGL_CONTEXT_MAJOR_VERSION,       4,
            c.EGL_CONTEXT_MINOR_VERSION,       3,
            c.EGL_CONTEXT_OPENGL_DEBUG,        c.EGL_TRUE,
            c.EGL_CONTEXT_OPENGL_PROFILE_MASK, c.EGL_CONTEXT_OPENGL_CORE_PROFILE_BIT,
            c.EGL_NONE,
        },
    ) orelse return error.EGLError;
    defer _ = c.eglDestroyContext(egl_dpy, egl_ctx);

    const output_windows = try std.heap.c_allocator.alloc(OutputWindow, globs.outputs.items.len);
    defer std.heap.c_allocator.free(output_windows);

    for (output_windows, 0..) |*output_window, i| {
        std.log.info("creating EGL surface #{}", .{i});
        const surface = try globs.compositor.createSurface();

        const lsurf = try globs.layer_shell.getLayerSurface(
            surface,
            globs.outputs.items[i],
            .background,
            "wlbg",
        );

        var winsize: ?[2]c_int = null;
        lsurf.setListener(*?[2]c_int, layerSurfaceListener, &winsize);

        lsurf.setAnchor(.{
            .top = true,
            .right = true,
            .bottom = true,
            .left = true,
        });
        lsurf.setExclusiveZone(-1);

        surface.commit();

        if (dpy.dispatch() != .SUCCESS) return error.DispatchFail;

        const egl_win = win: {
            std.log.info("creating EGL window #{}", .{i});
            const size = winsize orelse return error.DidNotGetWindowSize;
            break :win try wl.EglWindow.create(surface, size[0], size[1]);
        };
        errdefer egl_win.destroy();

        const egl_surface = c.eglCreateWindowSurface(
            egl_dpy,
            config,
            @ptrCast(egl_win),
            null,
        ) orelse return error.EGLError;
        errdefer _ = c.eglDestroySurface(egl_dpy, egl_surface);

        output_window.* = .{
            .egl_win = egl_win,
            .egl_surface = egl_surface,
            .surface = surface,
        };
    }
    defer for (output_windows) |output| output.deinit(egl_ctx);

    const r_timerfd = try std.posix.timerfd_create(std.posix.CLOCK.MONOTONIC, .{});
    defer std.posix.close(r_timerfd);

    var dth = DrawTimerHandler{
        .should_redraw = try std.heap.c_allocator.alloc(bool, output_info.len),
        .timerfd = r_timerfd,
    };
    defer std.heap.c_allocator.free(dth.should_redraw);
    @memset(dth.should_redraw, true);

    var pointer_state = PointerState{
        .active_surface_idx = null,
        .surface_positions = try std.heap.c_allocator.alloc([2]c_int, output_info.len),
    };
    defer std.heap.c_allocator.free(pointer_state.surface_positions);
    @memset(pointer_state.surface_positions, .{ 0, 0 });

    var pointer_listener_data = PointerListenerData{
        .pstate = &pointer_state,
        .outputs = output_windows,
        .dth = &dth,
    };

    const pointer = try globs.seat.getPointer();
    defer pointer.destroy();
    pointer.setListener(*PointerListenerData, pointerListener, &pointer_listener_data);

    const base_offset: [2]i32 = off: {
        if (comptime options.multihead_mode == .individual) break :off .{ 0, 0 };

        var total_width: i32 = 0;
        var total_height: i32 = 0;
        for (output_info) |inf| {
            const xmax = inf.x;
            const ymax = inf.y;

            if (xmax > total_width)
                total_width = xmax;
            if (ymax > total_height)
                total_height = ymax;
        }

        break :off .{
            @divTrunc(total_width, 2),
            @divTrunc(total_height, 2),
        };
    };

    if (c.eglMakeCurrent(
        egl_dpy,
        output_windows[0].egl_surface,
        output_windows[0].egl_surface,
        egl_ctx,
    ) != c.EGL_TRUE) return error.EGLError;

    c.glDebugMessageCallback(&glDebugCb, null);
    c.glEnable(c.GL_DEBUG_OUTPUT);
    std.log.info("initialized OpenGL {s}", .{c.glGetString(c.GL_VERSION)});

    var gfx = try Gfx.init(dpy, egl_dpy, output_info);
    defer gfx.deinit();

    var rdata = RenderData{
        .gfx = &gfx,
        .egl_dpy = egl_dpy,
        .egl_ctx = egl_ctx,
        .outputs = output_windows,
        .output_info = output_info,
        .last_time = std.time.milliTimestamp(),
        .base_offset = base_offset,
        .pointer_state = &pointer_state,
        .dth = &dth,
    };

    const rbg_timerfd = try std.posix.timerfd_create(std.posix.CLOCK.MONOTONIC, .{});
    defer std.posix.close(rbg_timerfd);

    try std.posix.timerfd_settime(r_timerfd, .{}, &DrawTimerHandler.timerspec, null);
    try std.posix.timerfd_settime(rbg_timerfd, .{}, &.{
        .it_value = .{ .tv_sec = 0, .tv_nsec = 1 },
        .it_interval = .{
            .tv_sec = @divTrunc(options.refresh_time, std.time.ms_per_s),
            .tv_nsec = @mod(options.refresh_time, std.time.ms_per_s) * std.time.ns_per_ms,
        },
    }, null);

    if (dpy.dispatchPending() != .SUCCESS) return error.RoundtipFail;
    std.debug.assert(dpy.prepareRead());

    const epfd = try std.posix.epoll_create1(0);
    defer std.posix.close(epfd);

    for ([_]std.posix.fd_t{ r_timerfd, rbg_timerfd, dpy.getFd() }) |fd| {
        var ev = std.os.linux.epoll_event{
            .data = .{ .fd = fd },
            .events = std.os.linux.EPOLL.IN,
        };

        try std.posix.epoll_ctl(epfd, std.os.linux.EPOLL.CTL_ADD, fd, &ev);
    }

    std.log.info("running event loop", .{});
    var events: [32]std.os.linux.epoll_event = undefined;
    while (true) {
        const evs = events[0..std.posix.epoll_wait(epfd, &events, -1)];
        for (evs) |ev| {
            var tfd_buf: [@sizeOf(usize)]u8 = undefined;
            if (ev.data.fd == dpy.getFd()) {
                try wlPoll(dpy);
            } else if (ev.data.fd == r_timerfd) {
                std.debug.assert(try std.posix.read(r_timerfd, &tfd_buf) == tfd_buf.len);
                try render(&rdata);
            } else if (ev.data.fd == rbg_timerfd) {
                std.debug.assert(try std.posix.read(rbg_timerfd, &tfd_buf) == tfd_buf.len);
                try renderBackground(&rdata);
            }
        }
    }
}

const RenderData = struct {
    gfx: *Gfx,
    egl_dpy: c.EGLDisplay,
    egl_ctx: c.EGLContext,
    outputs: []const OutputWindow,
    output_info: []const OutputInfo,
    last_time: i64,
    base_offset: [2]c_int,
    pointer_state: *PointerState,
    dth: *DrawTimerHandler,
};

fn render(data: *RenderData) !void {
    const now = std.time.milliTimestamp();
    const delta_time = now - data.last_time;
    data.last_time = now;

    try data.gfx.preDraw(
        delta_time,
        data.pointer_state,
        data.output_info,
        data.dth,
    );

    const should_disarm = data.dth.shouldDisarm();

    for (data.outputs, 0..) |output, i| {
        if (!data.dth.should_redraw[i])
            continue;

        if (c.eglMakeCurrent(
            data.egl_dpy,
            output.egl_surface,
            output.egl_surface,
            data.egl_ctx,
        ) != c.EGL_TRUE) {
            std.log.err("failed to set EGL context", .{});
            return error.EGLError;
        }

        try data.gfx.draw(
            delta_time,
            data.pointer_state,
            i,
            data.outputs,
            data.output_info,
            data.dth,
        );
    }

    if (data.dth.timerfd_active and should_disarm) {
        try std.posix.timerfd_settime(
            data.dth.timerfd,
            .{},
            &std.mem.zeroInit(std.os.linux.itimerspec, .{}),
            null,
        );
        data.dth.timerfd_active = false;
    }
}

fn renderBackground(data: *RenderData) !void {
    var rand: f32 = if (options.multihead_mode == .combined) std.crypto.random.float(f32) else 0.0;
    for (data.output_info, 0..) |info, i| {
        if (options.multihead_mode == .individual) rand = std.crypto.random.float(f32);
        try data.gfx.drawBackground(
            info,
            i,
            data.base_offset,
            rand,
        );
    }

    try data.dth.damageAll();
}

fn wlPoll(dpy: *wl.Display) !void {
    if (dpy.readEvents() != .SUCCESS)
        return error.DispatchFail;

    while (!dpy.prepareRead())
        if (dpy.dispatchPending() != .SUCCESS or dpy.flush() != .SUCCESS)
            return error.DispatchFail;
}

fn layerSurfaceListener(lsurf: *zwlr.LayerSurfaceV1, ev: zwlr.LayerSurfaceV1.Event, winsize: *?[2]c_int) void {
    switch (ev) {
        .configure => |configure| {
            winsize.* = .{ @intCast(configure.width), @intCast(configure.height) };
            lsurf.setSize(configure.width, configure.height);
            lsurf.ackConfigure(configure.serial);
        },
        else => {},
    }
}

fn xdgOutputListener(_: *zxdg.OutputV1, ev: zxdg.OutputV1.Event, info: *OutputInfo) void {
    switch (ev) {
        .logical_position => |pos| {
            info.x = pos.x;
            info.y = pos.y;
        },
        .logical_size => |size| {
            info.width = size.width;
            info.height = size.height;
        },
        else => {},
    }
}

const PointerListenerData = struct {
    pstate: *PointerState,
    outputs: []const OutputWindow,
    dth: *DrawTimerHandler,
};

fn pointerListener(_: *wl.Pointer, ev: wl.Pointer.Event, d: *PointerListenerData) void {
    switch (ev) {
        .motion => |motion| {
            if (d.pstate.active_surface_idx) |i| {
                d.pstate.surface_positions[i] = .{
                    motion.surface_x.toInt(),
                    motion.surface_y.toInt(),
                };
                d.dth.damage(i) catch {};
            }
        },
        .enter => |enter| {
            for (d.outputs, 0..) |out, i| {
                if (out.surface == enter.surface) {
                    d.dth.damage(i) catch {};
                    d.pstate.active_surface_idx = i;
                    break;
                }
            }
        },
        .leave => {
            if (d.pstate.active_surface_idx) |i| {
                d.dth.damage(i) catch {};
                d.pstate.active_surface_idx = null;
            }
        },
        else => {},
    }
}

fn glDebugCb(
    source: c.GLenum,
    @"type": c.GLenum,
    id: c.GLuint,
    severity: c.GLenum,
    len: c.GLsizei,
    msgp: ?[*:0]const u8,
    udata: ?*const anyopaque,
) callconv(.C) void {
    _ = source;
    _ = @"type";
    _ = id;
    _ = udata;
    const log = std.log.scoped(.gl);
    // Mesa likes to include trailing newlines sometimes
    const msg = std.mem.trim(u8, msgp.?[0..@intCast(len)], &std.ascii.whitespace);
    switch (severity) {
        c.GL_DEBUG_SEVERITY_HIGH => log.err("{s}", .{msg}),
        c.GL_DEBUG_SEVERITY_MEDIUM, c.GL_DEBUG_SEVERITY_LOW => log.warn("{s}", .{msg}),
        c.GL_DEBUG_SEVERITY_NOTIFICATION => log.info("{s}", .{msg}),
        else => unreachable,
    }
}
