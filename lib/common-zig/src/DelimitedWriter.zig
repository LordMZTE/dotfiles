//! Utility struct for building delimeter-separated strings

const std = @import("std");

writer: *std.Io.Writer,
delimiter: u8,
has_written: bool = false,

const Self = @This();

/// Push a string, inserting a delimiter if necessary
pub fn push(self: *Self, str: []const u8) !void {
    if (self.has_written) {
        try self.writer.writeByte(self.delimiter);
    }
    self.has_written = true;

    try self.writer.writeAll(str);
}

pub fn print(self: *Self, comptime fmt: []const u8, args: anytype) !void {
    if (self.has_written) {
        try self.writer.writeByte(self.delimiter);
    }
    self.has_written = true;

    try self.writer.print(fmt, args);
}
