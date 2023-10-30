const std = @import("std");

// Framerate
pub const fps = 30;

// Draw backgrounds aligned with same value or individually with different val.
pub const multihead_mode: enum { combined, individual } = .individual;

// Time between background changes
pub const refresh_time = std.time.ms_per_min * 5;
