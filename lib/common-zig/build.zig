const std = @import("std");

pub const confgen_json_opt = std.json.ParseOptions{ .ignore_unknown_fields = true };

pub fn build(b: *std.Build) void {
    _ = b.addModule("common", .{
        .root_source_file = b.path("src/main.zig"),
    });
}

// TODO: make confgen generate zon and delete
/// Retrieve some confgen options given a relative path to the dotfile root and a struct type
/// with a field for each option.
pub fn confgenGet(comptime T: type, alloc: std.mem.Allocator) !T {
    const cgopt_env = std.posix.getenv("CGOPTS");
    const optjson_path = optjson: {
        if (cgopt_env) |env| break :optjson env;
        const root = try findRepoRoot(alloc);
        defer alloc.free(root);

        break :optjson try std.fs.path.joinZ(alloc, &.{ root, "cgout/_cgfs/opts.json" });
    };
    defer if (cgopt_env == null) alloc.free(optjson_path);

    var file = try std.fs.cwd().openFileZ(optjson_path, .{});
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

pub fn findRepoRoot(alloc: std.mem.Allocator) ![:0]const u8 {
    if (std.fs.cwd().access(".git", .{})) |_|
        return try alloc.dupeZ(u8, ".")
    else |err| if (err != error.FileNotFound) return err;

    var buf: [std.fs.max_path_bytes]u8 = undefined;
    var i: usize = 0;

    // set 8 as an upper bound to directory depth
    for (0..8) |_| {
        @memcpy(buf[i..][0..3], "../");
        i += 3;
        const path_with_git = try std.fs.path.joinZ(alloc, &.{ buf[0..i], ".git" });
        defer alloc.free(path_with_git);

        if (std.fs.cwd().accessZ(path_with_git, .{})) |_|
            return try alloc.dupeZ(u8, buf[0..i])
        else |err| if (err != error.FileNotFound) return err;
    }

    return error.FileNotFound;
}
