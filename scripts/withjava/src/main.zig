const std = @import("std");
const opts = @import("opts");

pub const std_options = std.Options{
    .log_level = .debug,
    .logFn = @import("common").logFn,
};

pub fn main() !u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    if (std.os.argv.len < 3) {
        std.log.err("Not enough arguments, expected at least 2, got {}!", .{std.os.argv.len - 1});
        return 1;
    }

    var env = try std.process.getEnvMap(alloc);
    defer env.deinit();

    const jvm_basepath = opts.jvm orelse "/usr/lib/jvm";

    if (env.getPtr("PATH")) |path_p| {
        const newpath = try std.fmt.allocPrint(
            alloc,
            jvm_basepath ++ "/{s}/bin:{s}",
            .{ std.os.argv[1], path_p.* },
        );
        alloc.free(path_p.*);
        path_p.* = newpath;
    } else {
        const newpath = try std.fmt.allocPrint(alloc, jvm_basepath ++ "/{s}/bin", .{std.os.argv[1]});
        errdefer alloc.free(newpath);
        try env.putMove(try alloc.dupe(u8, "PATH"), newpath);
    }

    {
        const java_home = try std.fmt.allocPrint(alloc, jvm_basepath ++ "/{s}", .{std.os.argv[1]});
        errdefer alloc.free(java_home);
        try env.putMove(try alloc.dupe(u8, "JAVA_HOME"), java_home);
    }

    const child_argv = try alloc.alloc([]const u8, std.os.argv[2..].len);
    defer alloc.free(child_argv);

    for (std.os.argv[2..], child_argv) |a1, *a2|
        a2.* = std.mem.span(a1);

    var child = std.ChildProcess.init(child_argv, alloc);
    child.env_map = &env;
    const term = try child.spawnAndWait();

    switch (term) {
        .Exited => |ret| return ret,
        .Signal, .Stopped, .Unknown => |ret| {
            std.log.err("child signalled {}", .{ret});
            return 1;
        },
    }
}
