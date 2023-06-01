//! Shared code for script build scripts
const std = @import("std");

pub const confgen_json_opt = std.json.ParseOptions{ .ignore_unknown_fields = true };

/// Retrieve some confgen options given a path to the opts.json file and a struct type
/// with a field for each option.
pub fn confgenGet(comptime T: type, optsjson: []const u8, alloc: std.mem.Allocator) !T {
    var file = try std.fs.cwd().openFile(optsjson, .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());

    var reader = std.json.Reader(1024 * 8, @TypeOf(buf_reader.reader()))
        .init(alloc, buf_reader.reader());
    defer reader.deinit();

    return try std.json.parseFromTokenSource(T, alloc, &reader, confgen_json_opt);
    //return try std.json.parseFromSlice(T, alloc, out.stdout, confgen_json_opt);
}
