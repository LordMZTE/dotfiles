//! Shared code for script build scripts
const std = @import("std");

pub const confgen_json_opt = std.json.ParseOptions{ .ignore_unknown_fields = true };

/// Retrieve some confgen options given a path to the cgfile and a struct type
/// with a field for each option.
pub fn confgenGet(comptime T: type, cgfile: []const u8, alloc: std.mem.Allocator) !T {
    const info = @typeInfo(T);

    const field_names = comptime blk: {
        var names: [info.Struct.fields.len][]const u8 = undefined;
        for (info.Struct.fields, 0..) |f, i|
            names[i] = f.name;

        break :blk names;
    };

    const out = try std.ChildProcess.exec(.{
        .allocator = alloc,
        .argv = &[_][]const u8{ "confgen", "--json-opt", cgfile } ++ field_names,
    });
    defer {
        alloc.free(out.stdout);
        alloc.free(out.stderr);
    }

    if (!std.meta.eql(out.term, .{ .Exited = 0 }))
        return error.UnexpectedExitCode;

    return try std.json.parseFromSlice(T, alloc, out.stdout, confgen_json_opt);
}
