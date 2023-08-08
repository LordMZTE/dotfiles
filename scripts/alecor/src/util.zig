const std = @import("std");

/// A 2-dimensional heap-allocated matrix.
pub fn Matrix2D(comptime T: type) type {
    return struct {
        data: []T,
        width: usize,

        const Self = @This();

        pub inline fn init(alloc: std.mem.Allocator, height: usize, width: usize) !Self {
            return .{ .data = try alloc.alloc(T, height * width), .width = width };
        }

        pub inline fn deinit(self: Self, alloc: std.mem.Allocator) void {
            alloc.free(self.data);
        }

        pub inline fn el(self: *Self, row: usize, col: usize) *T {
            return &self.data[row * self.width + col];
        }
    };
}

/// Calculates the Damerau-Levenshtein distance between 2 strings
pub fn dist(alloc: std.mem.Allocator, a: []const u8, b: []const u8) !usize {
    var d = try Matrix2D(usize).init(alloc, a.len + 1, b.len + 1);
    defer d.deinit(alloc);

    @memset(d.data, 0);

    var i: usize = 0;
    var j: usize = 0;

    while (i <= a.len) : (i += 1) {
        d.el(i, 0).* = i;
    }

    while (j <= b.len) : (j += 1) {
        d.el(0, j).* = j;
    }

    i = 1;
    while (i <= a.len) : (i += 1) {
        j = 1;
        while (j <= b.len) : (j += 1) {
            const cost = @intFromBool(a[i - 1] != b[j - 1]);
            d.el(i, j).* = @min(
                d.el(i - 1, j).* + 1, // deletion
                @min(
                    d.el(i, j - 1).* + 1, // insertion
                    d.el(i - 1, j - 1).* + cost, // substitution
                ),
            );

            // transposition
            if (i > 1 and j > 1 and a[i - 1] == b[j - 2] and a[i - 2] == b[j - 1])
                d.el(i, j).* = @min(d.el(i, j).*, d.el(i - 2, j - 2).* + cost);
        }
    }

    return d.el(a.len, b.len).*;
}

fn formatCommand(
    cmd: []const []const u8,
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    _ = options;
    _ = fmt;

    var first = true;
    for (cmd) |arg| {
        defer first = false;
        var needs_quote = false;
        for (arg) |ch| {
            if (!std.ascii.isPrint(ch) or ch == '\'' or ch == ' ' or ch == '*' or ch == '$') {
                needs_quote = true;
                break;
            }
        }

        if (!first)
            try writer.writeByte(' ');

        if (needs_quote) {
            try writer.writeByte('"');
            try writer.print("{}", .{std.fmt.fmtSliceEscapeUpper(arg)});
            try writer.writeByte('"');
        } else {
            try writer.writeAll(arg);
        }
    }
}

pub fn fmtCommand(cmd: []const []const u8) std.fmt.Formatter(formatCommand) {
    return .{ .data = cmd };
}
