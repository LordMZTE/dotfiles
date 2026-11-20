//! This file contains a list of properties that we observe.
//! These are central instead of per-module since we'd otherwise get duplicates if multiple modules
//! observe a property.
const c = @import("c");

pub const ObserveProperty = struct {
    [*:0]const u8, // name
    c.mpv_format, // format
};

pub const observed_properties = [_]ObserveProperty{
    .{ "metadata", c.MPV_FORMAT_NODE }, // BetterTags
    .{ "stream-open-filename", c.MPV_FORMAT_STRING }, // LocalVids, LiveChat
    .{ "chapter", c.MPV_FORMAT_INT64 }, // SBSkip
};

pub const hooks = [_][*:0]const u8{
    "on_before_start_file", // LocalVids
    "on_load", // LocalVids
};
