//! Utility struct for building delimeter-separated strings
const std = @import("std");

str: []u8,
alloc: std.mem.Allocator,
delimeter: u8,

const DelimitedBuilder = @This();

pub fn init(alloc: std.mem.Allocator, delimeter: u8) DelimitedBuilder {
    return .{
        .str = "",
        .alloc = alloc,
        .delimeter = delimeter,
    };
}

pub fn deinit(self: DelimitedBuilder) void {
    if (self.str.len > 0) {
        self.alloc.free(self.str);
    }
}

/// Push a string, inserting a delimiter if necessary
pub fn push(self: *DelimitedBuilder, str: []const u8) !void {
    if (self.str.len == 0) {
        self.str = try self.alloc.dupe(u8, str);
    } else {
        const old_len = self.str.len;
        self.str = try self.alloc.realloc(self.str, old_len + str.len + 1);
        self.str[old_len] = self.delimeter;
        std.mem.copy(u8, self.str[old_len + 1 ..], str);
    }
}

/// Push a string without a delimiter
pub fn pushDirect(self: *DelimitedBuilder, str: []const u8) !void {
    if (self.str.len == 0) {
        self.str = try self.alloc.dupe(u8, str);
    } else {
        const old_len = self.str.len;
        self.str = try self.alloc.realloc(self.str, old_len + str.len);
        std.mem.copy(u8, self.str[old_len ..], str);
    }
}

/// Converts the builder's string to an allocated string.
/// Caller owns returned memory, the builder will be fully deinitialized.
pub fn toOwned(self: *const DelimitedBuilder) ![]u8 {
    if (self.str.len == 0) {
        return try self.alloc.alloc(u8, 0);
    } else {
        return self.str;
    }
}
