const std = @import("std");
const c = @import("ffi.zig").c;
const wayland = @import("wayland");

const glutil = @import("glutil.zig");
const options = @import("options.zig");

const DrawTimerHandler = @import("DrawTimerHandler.zig");
const OutputInfo = @import("OutputInfo.zig");
const OutputWindow = @import("OutputWindow.zig");
const PointerState = @import("PointerState.zig");

const wl = wayland.client.wl;

dpy: *wl.Display,
egl_dpy: c.EGLDisplay,
bg_shader_program: c_uint,
main_shader_program: c_uint,
bg_bufs: std.MultiArrayList(BgBuf),
time: i64,
cursor_positions: [][2]c_int,
vao: c_uint,
vbo: c_uint,

const Gfx = @This();

const BgBuf = struct {
    texture: c_uint,
    framebuffer: c_uint,
    zbuffer: c_uint,
};

pub fn init(dpy: *wl.Display, egl_dpy: c.EGLDisplay, output_info: []const OutputInfo) !Gfx {
    const bg_program = shader: {
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

        break :shader program;
    };

    const main_program = shader: {
        const vert_shader = try glutil.createShader(c.GL_VERTEX_SHADER, @embedFile("main_vert.glsl"));
        defer c.glDeleteShader(vert_shader);
        const frag_shader = try glutil.createShader(c.GL_FRAGMENT_SHADER, @embedFile("main_frag.glsl"));
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

        break :shader program;
    };

    const cursor_positions = try std.heap.c_allocator.alloc([2]c_int, output_info.len);
    errdefer std.heap.c_allocator.free(cursor_positions);
    @memset(cursor_positions, .{ 0, 0 });

    var bg_bufs = std.MultiArrayList(BgBuf){};
    errdefer bg_bufs.deinit(std.heap.c_allocator);

    try bg_bufs.resize(std.heap.c_allocator, output_info.len);

    const bg_slice = bg_bufs.slice();

    // @intCast safety: user is somewhat unlikely to have 2^32 - 1 monitors.
    c.glGenTextures(@intCast(output_info.len), bg_slice.items(.texture).ptr);
    errdefer c.glDeleteTextures(@intCast(bg_bufs.len), bg_slice.items(.texture).ptr);
    c.glGenFramebuffers(@intCast(output_info.len), bg_slice.items(.framebuffer).ptr);
    errdefer c.glDeleteFramebuffers(@intCast(bg_bufs.len), bg_slice.items(.framebuffer).ptr);
    c.glGenRenderbuffers(@intCast(output_info.len), bg_slice.items(.zbuffer).ptr);
    errdefer c.glDeleteRenderbuffers(@intCast(output_info.len), bg_slice.items(.zbuffer).ptr);

    for (
        output_info,
        bg_slice.items(.texture),
        bg_slice.items(.framebuffer),
        bg_slice.items(.zbuffer),
    ) |inf, tex, fb, zb| {
        c.glBindFramebuffer(c.GL_FRAMEBUFFER, fb);
        c.glBindTexture(c.GL_TEXTURE_2D, tex);
        c.glBindRenderbuffer(c.GL_RENDERBUFFER, zb);

        c.glTexImage2D(
            c.GL_TEXTURE_2D,
            0,
            c.GL_RGBA,
            inf.width,
            inf.height,
            0,
            c.GL_RGBA,
            c.GL_UNSIGNED_BYTE,
            null,
        );
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);
        c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);

        c.glFramebufferTexture2D(
            c.GL_FRAMEBUFFER,
            c.GL_COLOR_ATTACHMENT0,
            c.GL_TEXTURE_2D,
            tex,
            0,
        );

        c.glRenderbufferStorage(c.GL_RENDERBUFFER, c.GL_DEPTH_COMPONENT16, inf.width, inf.height);
        c.glFramebufferRenderbuffer(c.GL_FRAMEBUFFER, c.GL_DEPTH_ATTACHMENT, c.GL_RENDERBUFFER, zb);

        if (c.glCheckFramebufferStatus(c.GL_FRAMEBUFFER) != c.GL_FRAMEBUFFER_COMPLETE)
            return error.FramebufferIncomplete;
    }

    c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0);
    c.glBindTexture(c.GL_TEXTURE_2D, 0);
    c.glBindRenderbuffer(c.GL_RENDERBUFFER, 0);

    var vao: c_uint = 0;
    c.glGenVertexArrays(1, &vao);

    var vbo: c_uint = 0;
    c.glGenBuffers(1, &vbo);

    return .{
        .dpy = dpy,
        .egl_dpy = egl_dpy,
        .bg_shader_program = bg_program,
        .main_shader_program = main_program,
        .bg_bufs = bg_bufs,
        .time = 0,
        .cursor_positions = cursor_positions,
        .vao = vao,
        .vbo = vbo,
    };
}

pub fn deinit(self: *Gfx) void {
    const bg_slice = self.bg_bufs.slice();
    c.glDeleteTextures(@intCast(bg_slice.len), bg_slice.items(.texture).ptr);
    c.glDeleteFramebuffers(@intCast(bg_slice.len), bg_slice.items(.framebuffer).ptr);
    c.glDeleteRenderbuffers(@intCast(bg_slice.len), bg_slice.items(.zbuffer).ptr);
    self.bg_bufs.deinit(std.heap.c_allocator);

    c.glDeleteProgram(self.bg_shader_program);
    c.glDeleteProgram(self.main_shader_program);

    std.heap.c_allocator.free(self.cursor_positions);

    self.* = undefined;
}

pub fn preDraw(
    self: *Gfx,
    dt: i64,
    pointer_state: *PointerState,
    infos: []const OutputInfo,
    dth: *DrawTimerHandler,
) !void {
    for (self.cursor_positions, infos, 0..) |*pos, inf, i| {
        const lerp_amt = std.math.clamp(@as(f32, @floatFromInt(std.math.clamp(dt, 0, 10))) / 150.0, 0.0, 1.0);

        const target = if (pointer_state.active_surface_idx == i)
            pointer_state.surface_positions[i]
        else
            .{ @divTrunc(inf.width, 2), @divTrunc(inf.height, 2) };

        const new_x: c_int = @intFromFloat(std.math.lerp(
            @as(f32, @floatFromInt(pos[0])),
            @as(f32, @floatFromInt(target[0])),
            lerp_amt,
        ));
        const new_y: c_int = @intFromFloat(std.math.lerp(
            @as(f32, @floatFromInt(pos[1])),
            @as(f32, @floatFromInt(target[1])),
            lerp_amt,
        ));

        if (new_x != pos[0] or new_y != pos[1])
            try dth.damage(i);

        pos[0] = new_x;
        pos[1] = new_y;
    }
}

pub fn draw(
    self: *Gfx,
    dt: i64,
    pointer_state: *PointerState,
    output_idx: usize,
    outputs: []const OutputWindow,
    infos: []const OutputInfo,
    dth: *DrawTimerHandler,
) !void {
    self.time += dt;
    dth.should_redraw[output_idx] = false;
    c.glBindVertexArray(self.vao);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, self.vbo);
    c.glBindFramebuffer(c.GL_FRAMEBUFFER, 0); // use default framebuffer
    c.glUseProgram(self.main_shader_program);

    const vertices = [_]f32{
        -1.0, -1.0, 0.0, 0.0, 0.0,
        1.0,  -1.0, 0.0, 1.0, 0.0,
        1.0,  1.0,  0.0, 1.0, 1.0,

        -1.0, -1.0, 0.0, 0.0, 0.0,
        1.0,  1.0,  0.0, 1.0, 1.0,
        -1.0, 1.0,  0.0, 0.0, 1.0,
    };

    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(f32) * vertices.len, &vertices, c.GL_STATIC_DRAW);
    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, @sizeOf(f32) * 5, null);
    c.glEnableVertexAttribArray(0);
    c.glVertexAttribPointer(
        1,
        2,
        c.GL_FLOAT,
        c.GL_FALSE,
        @sizeOf(f32) * 5,
        @ptrFromInt(@sizeOf(f32) * 3),
    );
    c.glEnableVertexAttribArray(1);

    c.glClearColor(1.0, 0.0, 0.0, 1.0);
    c.glClear(c.GL_COLOR_BUFFER_BIT);

    c.glBindTexture(c.GL_TEXTURE_2D, self.bg_bufs.get(output_idx).texture);

    c.glUniform2f(
        c.glGetUniformLocation(self.main_shader_program, "cursorPos"),
        @as(f32, @floatFromInt(self.cursor_positions[output_idx][0])) / @as(f32, @floatFromInt(infos[output_idx].width)),
        1.0 - @as(f32, @floatFromInt(self.cursor_positions[output_idx][1])) / @as(f32, @floatFromInt(infos[output_idx].height)),
    );
    c.glUniform1f(
        c.glGetUniformLocation(self.main_shader_program, "hasCursor"),
        if (pointer_state.active_surface_idx == output_idx) 1.0 else 0.0,
    );
    //c.glUniform1f(
    //    c.glGetUniformLocation(self.main_shader_program, "time"),
    //    @as(f32, @floatFromInt(self.time)) / 1000.0,
    //);

    c.glDrawArrays(c.GL_TRIANGLES, 0, vertices.len / 3);

    // This is necessary because some EGL implementations (Mesa) will try reading the wayland
    // socket from eglSwapBuffers.
    // This causes a deadlock, is abysmal API design, and not preventable. It's gotten so bad
    // that another suggested workaround on the archive linked below is to put this on another
    // thread in order to force EGL to use its own wayland event queue.
    //
    // By cancelling the read operation first (which is always prep'd usually and handled by the
    // event loop), we can ensure that EGL gets to do its nonsense here before making libwayland
    // handle another read correctly by calling prepareRead again.
    //
    // Somehow the only trace of this BS on the entire internet and only reason I managed to figure
    // this out: https://lists.freedesktop.org/archives/wayland-devel/2013-March/007739.html
    self.dpy.cancelRead();
    if (c.eglSwapBuffers(
        self.egl_dpy,
        outputs[output_idx].egl_surface,
    ) != c.EGL_TRUE) return error.EGLError;
    while (!self.dpy.prepareRead())
        if (self.dpy.dispatchPending() != .SUCCESS) return error.RoundtipFail;
}

pub fn drawBackground(
    self: *Gfx,
    info: OutputInfo,
    output_idx: usize,
    base_off: [2]i32,
    rand: f32,
) !void {
    // There's just about a 0% chance this works properly when monitors have different resolutions,
    // but I can't even begin thinking about that.
    const off: struct { x: f32, y: f32 } = if (options.multihead_mode == .combined) .{
        .x = @as(f32, @floatFromInt(info.x - base_off[0])) / @as(f32, @floatFromInt(info.width)),
        .y = @as(f32, @floatFromInt(info.y - base_off[1])) / @as(f32, @floatFromInt(info.height)),
    } else .{ .x = 0, .y = 0 };

    const vertices = [_]f32{
        -1.0, -1.0, 0.0,
        1.0,  -1.0, 0.0,
        1.0,  1.0,  0.0,

        -1.0, -1.0, 0.0,
        1.0,  1.0,  0.0,
        -1.0, 1.0,  0.0,
    };

    c.glBindVertexArray(self.vao);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, self.vbo);
    c.glBindFramebuffer(c.GL_FRAMEBUFFER, self.bg_bufs.get(output_idx).framebuffer);

    c.glClearColor(1.0, 0.0, 0.0, 1.0);
    c.glClear(c.GL_COLOR_BUFFER_BIT);

    c.glUseProgram(self.bg_shader_program);

    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(f32) * vertices.len, &vertices, c.GL_STATIC_DRAW);
    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 0, null);
    c.glEnableVertexAttribArray(0);

    c.glUniform2f(c.glGetUniformLocation(self.bg_shader_program, "offset"), off.x, off.y);
    c.glUniform1f(c.glGetUniformLocation(self.bg_shader_program, "time"), rand * 2000.0 - 1000.0);

    c.glDrawArrays(c.GL_TRIANGLES, 0, vertices.len / 3);
}
