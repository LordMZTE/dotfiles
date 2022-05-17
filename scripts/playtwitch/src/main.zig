const std = @import("std");
const ffi = @import("ffi.zig");
const c = ffi.c;
const gui = @import("gui.zig");

pub fn log(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const g_level = switch (level) {
        .err => c.G_LOG_LEVEL_ERROR,
        .warn => c.G_LOG_LEVEL_WARNING,
        .info => c.G_LOG_LEVEL_INFO,
        .debug => c.G_LOG_LEVEL_DEBUG,
    };

    const s = std.fmt.allocPrintZ(
        std.heap.c_allocator,
        format,
        args,
    ) catch return;
    defer std.heap.c_allocator.free(s);

    var fields = [_]c.GLogField{
        c.GLogField{
            .key = "GLIB_DOMAIN",
            .value = "playtwitch-" ++ @tagName(scope),
            .length = -1,
        },
        c.GLogField{
            .key = "MESSAGE",
            .value = @ptrCast(*const anyopaque, s),
            .length = -1,
        },
    };

    c.g_log_structured_array(
        g_level,
        &fields,
        fields.len,
    );
}

pub fn main() !u8 {
    var udata_arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer udata_arena.deinit();

    var state = gui.GuiState {
        .alloc = std.heap.c_allocator,
        .udata_arena = udata_arena.allocator(),
    };

    const app = c.gtk_application_new("de.mzte.playtwitch", c.G_APPLICATION_FLAGS_NONE);
    defer c.g_object_unref(app);

    ffi.connectSignal(app, "activate", @ptrCast(c.GCallback, gui.activate), &state);

    const status = c.g_application_run(
        @ptrCast(*c.GApplication, app),
        @intCast(i32, std.os.argv.len),
        @ptrCast([*c][*c]u8, std.os.argv.ptr),
    );

    if (state.streamlink_child) |ch| {
        defer ch.deinit();
        _ = try ch.wait();
    }

    if (state.chatty_child) |ch| {
        defer ch.deinit();
        _ = try ch.wait();
    }

    return @intCast(u8, status);
}
