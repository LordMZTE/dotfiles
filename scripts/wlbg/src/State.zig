const std = @import("std");

const Output = @import("Output.zig");

wps: []const [:0]const u8,
outputs: std.ArrayList(*Output),
rand: std.Random.DefaultPrng,
sockpath: [:0]const u8,
