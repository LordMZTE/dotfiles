const std = @import("std");
const ffi = @import("ffi.zig");
const c = ffi.c;
const gui = @import("gui.zig");

pub const log = @import("glib-log").log(c, "playtwitch", 512);
// glib handles level filtering
pub const log_level = .debug;

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

    if (state.streamlink_child) |*ch| {
        _ = try ch.wait();
    }

    if (state.chatty_child) |*ch| {
        _ = try ch.wait();
    }

    return @intCast(u8, status);
}
