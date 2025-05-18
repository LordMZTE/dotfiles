const std = @import("std");
const c = ffi.c;
const opts = @import("opts");

const ffi = @import("../ffi.zig");
const util = @import("../util.zig");

const BackgroundColor = @This();

const Background = enum(u8) {
    transparent,
    ctp,
    ctp_transparent,
    black,

    fn next(self: Background) Background {
        return @enumFromInt((@intFromEnum(self) + 1) % 4);
    }

    fn color(self: Background) [:0]const u8 {
        return switch (self) {
            .transparent => "#00000000",
            .ctp => "#" ++ opts.ctp_base,
            .ctp_transparent => "#a0" ++ opts.ctp_base,
            .black => "#000000",
        };
    }
};

bg: Background,

pub fn create() BackgroundColor {
    return .{ .bg = .transparent };
}

pub fn setup(self: *BackgroundColor, mpv: *c.mpv_handle) !void {
    _ = self;
    _ = mpv;
}

pub fn deinit(self: *BackgroundColor) void {
    _ = self;
}

pub fn onEvent(self: *BackgroundColor, mpv: *c.mpv_handle, ev: *c.mpv_event) !void {
    // TODO: dedupe this
    switch (ev.event_id) {
        c.MPV_EVENT_CLIENT_MESSAGE => {
            const cmsg: *c.mpv_event_client_message = @ptrCast(@alignCast(ev.data));
            const args = cmsg.args[0..@intCast(cmsg.num_args)];

            if (args.len >= 3 and
                std.mem.orderZ(u8, args[0], "key-binding") == .eq and
                std.mem.orderZ(u8, args[1], "mzte-background") == .eq and
                (args[2][0] == 'd' or args[2][0] == 'p') // key was pressed
            ) try self.nextBackground(mpv);
        },
        else => {},
    }
}

fn nextBackground(self: *BackgroundColor, mpv: *c.mpv_handle) !void {
    self.bg = self.bg.next();
    try ffi.checkMpvError(c.mpv_set_property_string(
        mpv,
        "background-color",
        self.bg.color(),
    ));
    try util.msg(
        mpv,
        .@"background-color",
        "new color: {s}",
        .{@tagName(self.bg)},
    );
}
