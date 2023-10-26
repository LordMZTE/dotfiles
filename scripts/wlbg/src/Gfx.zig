const std = @import("std");
const c = @import("ffi.zig").c;

const glutil = @import("glutil.zig");

const OutputInfo = @import("OutputInfo.zig");

egl_dpy: c.EGLDisplay,
bg_shader_program: c_uint,
time: f64,

const Gfx = @This();

pub fn init(egl_dpy: c.EGLDisplay) !Gfx {
    const vert_shader = try glutil.createShader(c.GL_VERTEX_SHADER, @embedFile("bg_vert.glsl"));
    defer c.glDeleteShader(vert_shader);
    const frag_shader = try glutil.createShader(c.GL_FRAGMENT_SHADER, @embedFile("bg_frag.glsl"));
    defer c.glDeleteShader(frag_shader);

    const program = c.glCreateProgram();
    errdefer c.glDeleteProgram(program);
    c.glAttachShader(program, vert_shader);
    c.glAttachShader(program, frag_shader);
    c.glLinkProgram(program);

    var success: c_int = 0;
    c.glGetProgramiv(program, c.GL_LINK_STATUS, &success);
    if (success != 1)
        return error.ShaderLinkFail;

    return .{
        .egl_dpy = egl_dpy,
        .bg_shader_program = program,
        .time = 0.0,
    };
}

pub fn deinit(self: *Gfx) void {
    c.glDeleteProgram(self.bg_shader_program);
    self.* = undefined;
}

pub fn draw(
    self: *Gfx,
    dt: f32,
    egl_surface: c.EGLSurface,
    info: OutputInfo,
    base_xoff: i32,
    base_yoff: i32,
) !void {
    self.time += dt;

    // There's just about a 0% chance this works properly when monitors have different resolutions,
    // but I can't even begin thinking about that.
    const xoff = @as(f32, @floatFromInt(info.x - base_xoff)) / @as(f32, @floatFromInt(info.width));
    const yoff = @as(f32, @floatFromInt(info.y - base_yoff)) / @as(f32, @floatFromInt(info.height));

    const vertices = [_]f32{
        -1.0, -1.0, 0.0, xoff, yoff,
        1.0,  -1.0, 0.0, xoff, yoff,
        1.0,  1.0,  0.0, xoff, yoff,

        -1.0, -1.0, 0.0, xoff, yoff,
        1.0,  1.0,  0.0, xoff, yoff,
        -1.0, 1.0,  0.0, xoff, yoff,
    };

    c.glClearColor(1.0, 0.0, 0.0, 1.0);
    c.glClear(c.GL_COLOR_BUFFER_BIT);

    c.glUseProgram(self.bg_shader_program);

    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, @sizeOf(f32) * 5, &vertices);
    c.glEnableVertexAttribArray(0);

    c.glVertexAttribPointer(1, 2, c.GL_FLOAT, c.GL_FALSE, @sizeOf(f32) * 5, @ptrFromInt(@intFromPtr(&vertices) + @sizeOf(f32) * 3));
    c.glEnableVertexAttribArray(1);

    c.glUniform1f(c.glGetUniformLocation(self.bg_shader_program, "time"), @as(f32, @floatCast(self.time / 10000.0)));

    c.glDrawArrays(c.GL_TRIANGLES, 0, vertices.len / 3);

    if (c.eglSwapBuffers(self.egl_dpy, egl_surface) != c.EGL_TRUE) return error.EGLError;
}
