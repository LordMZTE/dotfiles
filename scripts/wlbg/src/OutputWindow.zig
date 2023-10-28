const wl = @import("wayland").client.wl;
const c = @import("ffi.zig").c;

egl_win: *wl.EglWindow,
egl_surface: c.EGLSurface,
surface: *wl.Surface,

const OutputWindow = @This();

pub fn deinit(self: OutputWindow, egl_dpy: c.EGLDisplay) void {
    self.egl_win.destroy();
    self.surface.destroy();
    _ = c.eglDestroySurface(egl_dpy, self.egl_surface);
}
