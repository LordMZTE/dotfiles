const std = @import("std");
const c = @import("ffi.zig").c;
const gui = @import("gui.zig");
const State = @import("State.zig");
const log = std.log.scoped(.main);

pub const std_options = std.Options{
    .log_level = .debug,
};

pub fn main() !void {
    log.info("initializing GLFW", .{});
    _ = c.glfwSetErrorCallback(&glfwErrorCb);
    if (c.glfwInit() == 0) {
        return error.GlfwInit;
    }

    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_TRANSPARENT_FRAMEBUFFER, c.GLFW_TRUE);

    log.info("creating window", .{});
    const win = c.glfwCreateWindow(500, 500, "playtwitch", null, null);
    defer c.glfwTerminate();

    c.glfwMakeContextCurrent(win);
    c.glfwSwapInterval(1);

    log.info("initializing GLEW", .{});
    const glew_err = c.glewInit();
    if (glew_err != c.GLEW_OK) {
        std.log.err("GLEW init error: {s}", .{c.glewGetErrorString(glew_err)});
        return error.GlewInit;
    }

    log.info("initializing ImGui", .{});
    const ctx = c.igCreateContext(null);
    defer c.igDestroyContext(ctx);

    const io = c.igGetIO();
    io.*.ConfigFlags |= c.ImGuiConfigFlags_NavEnableKeyboard;
    io.*.IniFilename = null;
    io.*.LogFilename = null;

    _ = c.ImGui_ImplGlfw_InitForOpenGL(win, true);
    defer c.ImGui_ImplGlfw_Shutdown();

    _ = c.ImGui_ImplOpenGL3_Init("#version 330 core");
    defer c.ImGui_ImplOpenGL3_Shutdown();

    c.igStyleColorsDark(null);
    @import("theme.zig").loadTheme(&c.igGetStyle().*.Colors);
    const font = try @import("theme.zig").loadFont();

    const state = try State.init(win.?);
    defer state.deinit();

    while (c.glfwWindowShouldClose(win) == 0) {
        if (c.glfwGetWindowAttrib(win, c.GLFW_VISIBLE) == 0)
            continue;

        c.glfwPollEvents();

        var win_width: c_int = 0;
        var win_height: c_int = 0;
        c.glfwGetWindowSize(win, &win_width, &win_height);

        c.ImGui_ImplOpenGL3_NewFrame();
        c.ImGui_ImplGlfw_NewFrame();
        c.igNewFrame();
        if (font) |f|
            c.igPushFont(f);

        const win_visible = c.igBegin(
            "##main_win",
            null,
            c.ImGuiWindowFlags_NoMove |
                c.ImGuiWindowFlags_NoResize |
                c.ImGuiWindowFlags_NoDecoration |
                c.ImGuiWindowFlags_NoBringToFrontOnFocus |
                c.ImGuiWindowFlags_NoNavFocus,
        );

        c.igSetWindowPos_Vec2(
            .{ .x = 0.0, .y = 0.0 },
            c.ImGuiCond_Always,
        );
        c.igSetWindowSize_Vec2(
            .{ .x = @floatFromInt(win_width), .y = @floatFromInt(win_height) },
            c.ImGuiCond_Always,
        );

        if (win_visible) {
            try gui.winContent(state);
        }

        if (font != null)
            c.igPopFont();

        c.igEnd();

        c.igEndFrame();

        c.glViewport(0, 0, win_width, win_height);
        c.glClear(c.GL_COLOR_BUFFER_BIT);
        c.glClearColor(0.0, 0.0, 0.0, 0.0);

        c.igRender();
        c.ImGui_ImplOpenGL3_RenderDrawData(c.igGetDrawData());
        c.glfwSwapBuffers(win);
    }
}

fn glfwErrorCb(e: c_int, d: [*c]const u8) callconv(.C) void {
    log.err("GLFW error {d}: {s}", .{ e, d });
}
