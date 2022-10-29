const std = @import("std");
const c = @import("ffi.zig").c;

pub fn sliceText(text: []const u8) void {
    c.igTextUnformatted(text.ptr, text.ptr + text.len);
}
