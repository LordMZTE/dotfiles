const std = @import("std");

pub fn delimitedWriter(writer: anytype, delimeter: u8) DelimitedWriter(@TypeOf(writer)) {
    return DelimitedWriter(@TypeOf(writer)).init(writer, delimeter);
}

/// Utility struct for building delimeter-separated strings
pub fn DelimitedWriter(comptime Writer: type) type {
    return struct {
        writer: Writer,
        delimeter: u8,
        has_written: bool,

        const Self = @This();

        pub fn init(writer: Writer, delimeter: u8) Self {
            return .{
                .writer = writer,
                .delimeter = delimeter,
                .has_written = false,
            };
        }

        /// Push a string, inserting a delimiter if necessary
        pub fn push(self: *Self, str: []const u8) !void {
            if (self.has_written) {
                try self.writer.writeByte(self.delimeter);
            }
            self.has_written = true;

            try self.writer.writeAll(str);
        }
    };
}
