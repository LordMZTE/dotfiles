const std = @import("std");
const c = ffi.c;

const ffi = @import("ffi.zig");
const util = @import("util.zig");

pub const std_options = std.Options{
    .log_level = .debug,
    .logFn = struct {
        fn logFn(
            comptime message_level: std.log.Level,
            comptime scope: @TypeOf(.enum_literal),
            comptime format: []const u8,
            args: anytype,
        ) void {
            _ = scope;

            const stderr = std.io.getStdErr().writer();

            stderr.print("[mzte-mpv {s}] " ++ format ++ "\n", .{@tagName(message_level)} ++ args) catch return;
        }
    }.logFn,
};

export fn mpv_open_cplugin(handle: *c.mpv_handle) callconv(.C) c_int {
    tryMain(handle) catch |e| {
        if (@errorReturnTrace()) |ert|
            std.debug.dumpStackTrace(ert.*);
        std.log.err("FATAL: {}\n", .{e});
        return -1;
    };
    return 0;
}

fn tryMain(mpv: *c.mpv_handle) !void {
    var modules = .{
        @import("modules/LiveChat.zig").create(),
        @import("modules/SBSkip.zig").create(),
    };
    // need this weird loop here for pointer access for fields to work
    inline for (comptime std.meta.fieldNames(@TypeOf(modules))) |f|
        try @field(modules, f).setup(mpv);
    defer inline for (comptime std.meta.fieldNames(@TypeOf(modules))) |f|
        @field(modules, f).deinit();

    std.log.info("loaded with client name '{s}'", .{c.mpv_client_name(mpv)});

    while (true) {
        const ev = @as(*c.mpv_event, c.mpv_wait_event(mpv, -1));
        try ffi.checkMpvError(ev.@"error");
        inline for (comptime std.meta.fieldNames(@TypeOf(modules))) |f|
            try @field(modules, f).onEvent(mpv, ev);
        if (ev.event_id == c.MPV_EVENT_SHUTDOWN) break;
    }
}
