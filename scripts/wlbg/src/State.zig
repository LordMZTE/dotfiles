const std = @import("std");

alloc: std.mem.Allocator,
wps: []const [:0]const u8,
rand: std.Random.DefaultPrng,
sockpath: [:0]const u8,
