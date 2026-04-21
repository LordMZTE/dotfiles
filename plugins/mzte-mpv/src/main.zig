const std = @import("std");
const common = @import("common");
const c = @import("c");

const ffi = @import("ffi.zig");
const util = @import("util.zig");

const State = @import("State.zig");

pub const std_options = std.Options{
    .log_level = .debug,
    .logFn = common.logFn,
};

pub const mztecommon_opts = common.Opts{
    .log_pfx = "mzte-mpv",
    .log_clear_line = true,
};

export fn mpv_open_cplugin(handle: *c.mpv_handle) callconv(.c) c_int {
    tryMain(handle) catch |e| {
        if (@errorReturnTrace()) |ert|
            std.debug.dumpErrorReturnTrace(ert);
        std.log.err("FATAL: {}\n", .{e});
        return -1;
    };
    return 0;
}

fn tryMain(mpv: *c.mpv_handle) !void {
    var io_impl: std.Io.Threaded = .init(std.heap.c_allocator, .{});
    defer io_impl.deinit();
    const io = io_impl.io();

    var state: State = .{
        .job_pool = .init,
    };
    defer state.job_pool.cancel(io);

    var modules = .{
        @import("modules/BackgroundColor.zig").create(io),
        @import("modules/BetterTags.zig").create(io),
        @import("modules/LiveChat.zig").create(io),
        @import("modules/LocalVids.zig").create(io),
        @import("modules/SBSkip.zig").create(io),
        @import("modules/ScreenshotOpen.zig").create(io),
        @import("modules/Shuffle.zig").create(io),
    };

    // need this weird loop here for pointer access for fields to work
    inline for (comptime std.meta.fieldNames(@TypeOf(modules))) |f|
        try @field(modules, f).setup(mpv);
    defer inline for (comptime std.meta.fieldNames(@TypeOf(modules))) |f|
        @field(modules, f).deinit();

    try ffi.checkMpvError(c.mpv_hook_add(mpv, 0, "on_before_start_file", 0));
    try ffi.checkMpvError(c.mpv_hook_add(mpv, 0, "on_load", 0));

    std.log.info("loaded with client name '{s}'", .{c.mpv_client_name(mpv)});

    while (true) {
        const ev = @as(*c.mpv_event, c.mpv_wait_event(mpv, -1));
        try ffi.checkMpvError(ev.@"error");
        inline for (comptime std.meta.fieldNames(@TypeOf(modules))) |f|
            try @field(modules, f).onEvent(mpv, io, &state, ev);

        switch (ev.event_id) {
            c.MPV_EVENT_SHUTDOWN => break,
            c.MPV_EVENT_HOOK => {
                const hookev: *c.mpv_event_hook = @ptrCast(@alignCast(ev.data));

                try ffi.checkMpvError(c.mpv_hook_continue(mpv, hookev.id));
            },
            else => {},
        }
    }
}
