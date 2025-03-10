const std = @import("std");
const c = ffi.c;

const ffi = @import("../ffi.zig");
const util = @import("../util.zig");

const Shuffle = @This();

shuffled: bool,

pub fn create() Shuffle {
    return .{ .shuffled = false };
}

pub fn setup(self: *Shuffle, mpv: *c.mpv_handle) !void {
    _ = self;
    _ = mpv;
}

pub fn deinit(self: *Shuffle) void {
    _ = self;
}

pub fn onEvent(self: *Shuffle, mpv: *c.mpv_handle, ev: *c.mpv_event) !void {
    switch (ev.event_id) {
        c.MPV_EVENT_CLIENT_MESSAGE => {
            const cmsg: *c.mpv_event_client_message = @ptrCast(@alignCast(ev.data));
            const args = cmsg.args[0..@intCast(cmsg.num_args)];
            std.debug.assert(std.mem.span(args[2]).len >= 3);

            if (args.len >= 3 and
                std.mem.orderZ(u8, args[0], "key-binding") == .eq and
                std.mem.orderZ(u8, args[1], "mzte-shuffle") == .eq and
                (args[2][0] == 'd' or args[2][0] == 'p') // key was pressed
            ) try self.toggleShuffle(mpv);
        },
        else => {},
    }
}

fn toggleShuffle(self: *Shuffle, mpv: *c.mpv_handle) !void {
    const cmd = if (self.shuffled) "playlist-unshuffle" else "playlist-shuffle";
    try ffi.checkMpvError(c.mpv_command_async(
        mpv,
        0,
        @constCast(&[_:null]?[*]const u8{cmd.ptr}),
    ));
    self.shuffled = !self.shuffled;
    try util.msg(mpv, .shuffle, "shuffled: {}", .{self.shuffled});
}
