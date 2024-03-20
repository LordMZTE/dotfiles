const std = @import("std");

pub const confgen_json_opt = std.json.ParseOptions{ .ignore_unknown_fields = true };

pub fn build(b: *std.Build) void {
    _ = b.addModule("common", .{
        .root_source_file = .{ .path = "src/main.zig" },
    });
}

// TODO: make confgen generate zon and delete
/// Retrieve some confgen options given a relative path to the dotfile root and a struct type
/// with a field for each option.
pub fn confgenGet(comptime T: type, alloc: std.mem.Allocator) !T {
    const optjson_path = comptime std.fs.path.dirname(@src().file).? ++ "/../../cgout/opts.json";
    var file = try std.fs.cwd().openFile(optjson_path, .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());

    var reader = std.json.Reader(1024 * 8, @TypeOf(buf_reader.reader()))
        .init(alloc, buf_reader.reader());
    defer reader.deinit();

    const ret = try std.json.parseFromTokenSource(T, alloc, &reader, confgen_json_opt);

    // We just grab the value from the parse result as this data will almost certainly have been
    // allocated with the builder's arena anyways.
    return ret.value;
}
