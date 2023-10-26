const std = @import("std");
const xev = @import("xev");
const wayland = @import("wayland");

const c = @import("ffi.zig").c;

const Gfx = @import("Gfx.zig");
const Globals = @import("Globals.zig");
const OutputInfo = @import("OutputInfo.zig");

const wl = wayland.client.wl;
const zwlr = wayland.client.zwlr;
const zxdg = wayland.client.zxdg;

const fps = 10;

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
        };
    }
    defer for (output_windows) |output| output.deinit(egl_ctx);

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

    const base_xoff = @divTrunc(total_width, 2);
    const base_yoff = @divTrunc(total_height, 2);

    if (c.eglMakeCurrent(
        egl_dpy,
        output_windows[0].egl_surface,
        output_windows[0].egl_surface,
        egl_ctx,
    ) != c.EGL_TRUE) return error.EGLError;

    var gfx = try Gfx.init(egl_dpy);
    defer gfx.deinit();

    var timer = try std.time.Timer.start();
    var prev_time = std.time.milliTimestamp();
    while (true) {
        const now_time = std.time.milliTimestamp();
        const delta_time: f32 = @floatFromInt(now_time - prev_time);
        prev_time = now_time;

        for (output_windows, output_info) |output, info| {
            if (c.eglMakeCurrent(
                egl_dpy,
                output.egl_surface,
                output.egl_surface,
                egl_ctx,
            ) != c.EGL_TRUE) return error.EGLError;
            try gfx.draw(delta_time, output.egl_surface, info, base_xoff, base_yoff);
        }

        if (dpy.dispatchPending() != .SUCCESS or dpy.flush() != .SUCCESS) {
            std.log.err("error processing wayland events", .{});
            return error.DispatchFail;
        }

        const elapsed = timer.lap();
        if (elapsed < 1000 * std.time.ns_per_ms / fps)
            std.os.nanosleep(0, (1000 * std.time.ns_per_ms) / fps - elapsed);
    }
}

const OutputWindow = struct {
    egl_win: *wl.EglWindow,
    egl_surface: c.EGLSurface,

    fn deinit(self: OutputWindow, egl_dpy: c.EGLDisplay) void {
        self.egl_win.destroy();
        _ = c.eglDestroySurface(egl_dpy, self.egl_surface);
    }
};

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
