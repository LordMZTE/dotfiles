const std = @import("std");
const common = @import("common");
const c = ffi.c;

const ffi = @import("ffi.zig");
const util = @import("util.zig");

pub const std_options = std.Options{
    .log_level = .debug,
    .logFn = common.logFn,
};

pub const mztecommon_opts = common.Opts{
    .log_pfx = "mzte-mpv",
    .log_clear_line = true,
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
        @import("modules/BackgroundColor.zig").create(),
        @import("modules/LiveChat.zig").create(),
        @import("modules/SBSkip.zig").create(),
        @import("modules/ScreenshotOpen.zig").create(),
        @import("modules/Shuffle.zig").create(),
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
