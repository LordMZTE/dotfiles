const std = @import("std");
const xev = @import("xev");
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

pub const std_options = struct {
    pub const log_level = .debug;
};

pub fn main() !void {
    std.log.info("initializing event loop", .{});
    var loop = try xev.Loop.init(.{});
    defer loop.deinit();

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
                c.EGL_RENDERABLE_TYPE, c.EGL_OPENGL_ES2_BIT,
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
            c.EGL_CONTEXT_MAJOR_VERSION, 2,
            c.EGL_CONTEXT_OPENGL_DEBUG,  1,
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

    var r_timer_completion: xev.Completion = undefined;
    var r_timer = try xev.Timer.init();
    defer r_timer.deinit();

    var dth = DrawTimerHandler{
        .should_redraw = try std.heap.c_allocator.alloc(bool, output_info.len),
        .completion = &r_timer_completion,
        .loop = &loop,
    };
    defer std.heap.c_allocator.free(dth.should_redraw);
    @memset(dth.should_redraw, true);

    var pointer_state = PointerState{
        .surface = null,
        .x = 0,
        .y = 0,
    };

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

    var gfx = try Gfx.init(egl_dpy, output_info);
    defer gfx.deinit();

    var rdata = RenderData{
        .gfx = &gfx,
        .egl_dpy = egl_dpy,
        .egl_ctx = egl_ctx,
        .outputs = output_windows,
        .output_info = output_info,
        .last_time = loop.now(),
        .base_offset = base_offset,
        .pointer_state = &pointer_state,
        .dth = &dth,
    };

    var rbg_timer_completion: xev.Completion = undefined;
    var rbg_timer = try xev.Timer.init();
    defer rbg_timer.deinit();

    rbg_timer.run(
        &loop,
        &rbg_timer_completion,
        0,
        RenderData,
        &rdata,
        renderBackgroundCb,
    );

    r_timer.run(
        &loop,
        &r_timer_completion,
        0,
        RenderData,
        &rdata,
        renderCb,
    );

    var wl_poll_completion = xev.Completion{
        .op = .{ .poll = .{ .fd = dpy.getFd() } },
        .userdata = dpy,
        .callback = wlPollCb,
    };
    loop.add(&wl_poll_completion);

    std.log.info("running event loop", .{});
    try loop.run(.until_done);
}

const RenderData = struct {
    gfx: *Gfx,
    egl_dpy: c.EGLDisplay,
    egl_ctx: c.EGLContext,
    outputs: []const OutputWindow,
    output_info: []const OutputInfo,
    last_time: isize,
    base_offset: [2]c_int,
    pointer_state: *PointerState,
    dth: *DrawTimerHandler,
};

fn renderCb(
    data: ?*RenderData,
    loop: *xev.Loop,
    completion: *xev.Completion,
    result: xev.Timer.RunError!void,
) xev.CallbackAction {
    _ = completion;
    result catch unreachable;

    const now = loop.now();
    const delta_time = now - data.?.last_time;
    data.?.last_time = now;

    data.?.dth.resetTimer();

    data.?.gfx.preDraw(
        delta_time,
        data.?.pointer_state,
        data.?.outputs,
        data.?.output_info,
        data.?.dth,
    ) catch |e| {
        std.log.err("running preDraw: {}", .{e});
        loop.stop();
        return .disarm;
    };

    for (data.?.outputs, 0..) |output, i| {
        if (!data.?.dth.should_redraw[i])
            continue;

        if (c.eglMakeCurrent(
            data.?.egl_dpy,
            output.egl_surface,
            output.egl_surface,
            data.?.egl_ctx,
        ) != c.EGL_TRUE) {
            std.log.err("failed to set EGL context", .{});
            loop.stop();
            return .disarm;
        }

        data.?.gfx.draw(
            delta_time,
            data.?.pointer_state,
            i,
            data.?.outputs,
            data.?.output_info,
            data.?.dth,
        ) catch |e| {
            std.log.err("drawing: {}", .{e});
            loop.stop();
            return .disarm;
        };
    }

    return data.?.dth.nextAction();
}

fn renderBackgroundCb(
    data: ?*RenderData,
    loop: *xev.Loop,
    completion: *xev.Completion,
    result: xev.Timer.RunError!void,
) xev.CallbackAction {
    result catch unreachable;

    resetXevTimerCompletion(completion, loop.now(), options.refresh_time);

    var rand: f32 = if (options.multihead_mode == .combined) std.crypto.random.float(f32) else 0.0;
    for (data.?.output_info, 0..) |info, i| {
        if (options.multihead_mode == .individual) rand = std.crypto.random.float(f32);
        data.?.gfx.drawBackground(
            info,
            i,
            data.?.base_offset,
            rand,
        ) catch |e| {
            std.log.err("drawing background: {}", .{e});
            loop.stop();
            return .disarm;
        };
    }

    data.?.dth.damageAll();

    return .rearm;
}

fn wlPollCb(
    userdata: ?*anyopaque,
    loop: *xev.Loop,
    _: *xev.Completion,
    result: xev.Result,
) xev.CallbackAction {
    result.poll catch |e| {
        std.log.err("unable to poll wayland FD: {}", .{e});
        loop.stop();
        return .disarm;
    };

    const dpy: *wl.Display = @ptrCast(@alignCast(userdata));
    if (dpy.dispatchPending() != .SUCCESS or dpy.flush() != .SUCCESS) {
        std.log.err("error processing wayland events", .{});
        loop.stop();
        return .disarm;
    }

    return .rearm;
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

    fn damageCurrentWindow(self: *PointerListenerData) !void {
        if (self.pstate.surface) |ps| {
            for (self.outputs, 0..) |o, i| {
                if (ps == o.surface) {
                    self.dth.damage(i);
                }
            }
        }
    }
};

fn pointerListener(_: *wl.Pointer, ev: wl.Pointer.Event, d: *PointerListenerData) void {
    switch (ev) {
        .motion => |motion| {
            d.pstate.x = motion.surface_x.toInt();
            d.pstate.y = motion.surface_y.toInt();
            d.damageCurrentWindow() catch |e| {
                std.log.err("unable to damage window: {}", .{e});
            };
        },
        .enter => |enter| {
            d.pstate.surface = enter.surface;
            d.damageCurrentWindow() catch |e| {
                std.log.err("unable to damage window: {}", .{e});
            };
        },
        .leave => {
            d.damageCurrentWindow() catch |e| {
                std.log.err("unable to damage window: {}", .{e});
            };
            d.pstate.surface = null;
        },
        else => {},
    }
}

fn resetXevTimerCompletion(completion: *xev.Completion, now: i64, in: i64) void {
    const next_time = now + in;
    completion.op.timer.reset = .{
        .tv_sec = @divTrunc(next_time, std.time.ms_per_s),
        .tv_nsec = @mod(next_time, std.time.ms_per_s) * std.time.ns_per_ms,
    };
}
