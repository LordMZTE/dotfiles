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

    var state = gui.GuiState{
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

    if (state.streamlink_child) |*sl_child| {
        try runChildren(sl_child, if (state.chatty_child) |*ch| ch else null);
    }

    return @intCast(u8, status);
}

fn runChildren(sl_child: *std.ChildProcess, chatty_child: ?*std.ChildProcess) !void {
    var sl_alive = true;
    var thread: ?std.Thread = null;
    if (chatty_child) |chatty| {
        thread = try std.Thread.spawn(
            .{},
            waitAndRunChatty,
            .{ chatty, &sl_alive },
        );
    }

    sl_child.stdout_behavior = .Pipe;
    try sl_child.spawn();
    const output = try sl_child.stdout.?.readToEndAlloc(
        std.heap.c_allocator,
        std.math.maxInt(usize),
    );
    defer std.heap.c_allocator.free(output);
    const term = try sl_child.wait();
    if (term == .Exited and term.Exited != 0) {
        @atomicStore(bool, &sl_alive, false, .Unordered);
        std.log.err("Streamlink died:\n{s}", .{output});
        gui.showStreamlinkErrorDialog(std.mem.trimRight(u8, output, "\n\t "));
        if (thread) |*t| {
            t.detach();
        }
    } else {
        if (thread) |*t| {
            t.join();
        }
    }
}

// This function first waits a while, then checks if streamlink is still alive
// and then runs chatty.
fn waitAndRunChatty(chatty: *std.ChildProcess, sl_alive: *bool) !void {
    std.time.sleep(5 * std.time.ns_per_s);
    if (@atomicLoad(bool, sl_alive, .Unordered)) {
        _ = try chatty.spawnAndWait();
    }
}
