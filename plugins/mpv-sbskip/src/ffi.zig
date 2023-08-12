const std = @import("std");
pub const c = @cImport({
    @cInclude("mpv/client.h");
});

pub fn checkMpvError(err: c_int) !void {
    if (err >= 0)
        return;

    return switch (err) {
        c.MPV_ERROR_EVENT_QUEUE_FULL => error.EventQueueFull,
        c.MPV_ERROR_NOMEM => error.OutOfMemory,
        c.MPV_ERROR_UNINITIALIZED => error.Uninitialized,
        c.MPV_ERROR_INVALID_PARAMETER => error.InvalidParameter,
        c.MPV_ERROR_OPTION_NOT_FOUND => error.OptionNotFound,
        c.MPV_ERROR_OPTION_FORMAT => error.OptionFormat,
        c.MPV_ERROR_OPTION_ERROR => error.OptionError,
        c.MPV_ERROR_PROPERTY_NOT_FOUND => error.PropertyNotFound,
        c.MPV_ERROR_PROPERTY_FORMAT => error.PropertyFormat,
        c.MPV_ERROR_PROPERTY_UNAVAILABLE => error.PropertyUnavailable,
        c.MPV_ERROR_PROPERTY_ERROR => error.PropertyError,
        c.MPV_ERROR_COMMAND => error.Command,
        c.MPV_ERROR_LOADING_FAILED => error.LoadingFailed,
        c.MPV_ERROR_AO_INIT_FAILED => error.AOInitFailed,
        c.MPV_ERROR_VO_INIT_FAILED => error.VOInitFailed,
        c.MPV_ERROR_NOTHING_TO_PLAY => error.NothingToPlay,
        c.MPV_ERROR_UNKNOWN_FORMAT => error.UnknownFormat,
        c.MPV_ERROR_UNSUPPORTED => error.Unsupported,
        c.MPV_ERROR_NOT_IMPLEMENTED => error.NotImplemented,
        c.MPV_ERROR_GENERIC => error.Generic,
        else => error.Unknown,
    };
}
