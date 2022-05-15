const std = @import("std");
const ffi = @import("ffi.zig");
const u = @import("util.zig");
const c = ffi.c;
const gui = @import("gui.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();

    var state = gui.GuiState{
        .alloc = std.heap.c_allocator,
        .user_data_arena = arena.allocator(),
    };

    const app = c.gtk_application_new("de.mzte.gpower2", c.G_APPLICATION_FLAGS_NONE);
    defer c.g_object_unref(app);

    ffi.connectSignal(app, "activate", @ptrCast(c.GCallback, gui.activate), &state);

    const status = c.g_application_run(
        u.c(*c.GApplication, app),
        @intCast(i32, std.os.argv.len),
        u.c([*c][*c]u8, std.os.argv.ptr),
    );

    if (state.child) |*ch| {
        _ = try ch.wait();
    }

    std.os.exit(@intCast(u8, status));
}
