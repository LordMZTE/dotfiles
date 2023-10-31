const std = @import("std");

pub const Serverbound = union(enum) {
    ping,
    getenv: []const u8,
};

pub const Clientbound = union(enum) {
    pong,
    getenv_res: ?[]const u8,
};

