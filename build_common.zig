//! Shared code for script build scripts
const std = @import("std");

pub const confgen_json_opt = std.json.ParseOptions{ .ignore_unknown_fields = true };

/// Retrieve some confgen options given a relative path to the dotfile root and a struct type
/// with a field for each option.
pub fn confgenGet(comptime T: type, root_path: []const u8, alloc: std.mem.Allocator) !T {
    const optsjson = try std.fs.path.join(alloc, &.{ root_path, "cgout", "opts.json" });
    defer alloc.free(optsjson);

    var file = try std.fs.cwd().openFile(optsjson, .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());

    var reader = std.json.Reader(1024 * 8, @TypeOf(buf_reader.reader()))
        .init(alloc, buf_reader.reader());
    defer reader.deinit();

    // We just grab the value from the parse result as this data will almost certainly have been
    // allocated with the builder's arena anyways.
    return (try std.json.parseFromTokenSource(T, alloc, &reader, confgen_json_opt)).value;
}
