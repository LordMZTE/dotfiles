const std = @import("std");

var stderr_isatty: ?bool = null;

pub var log_file: ?std.fs.File = null;

pub fn logFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.enum_literal),
    comptime fmt: []const u8,
    args: anytype,
) void {
    const log_pfx: ?[]const u8 = if (@hasDecl(@import("root"), "mztecommon_log_pfx"))
        @import("root").mztecommon_log_pfx
    else
        null;

    const color = log_file == null and stderr_isatty orelse blk: {
        const isatty = std.os.isatty(std.os.STDERR_FILENO);
        stderr_isatty = isatty;
        break :blk isatty;
    };

    const logfile = log_file orelse std.io.getStdErr();

    const scope_prefix = if (log_pfx) |lpfx|
        if (scope != .default)
            "[" ++ lpfx ++ " " ++ @tagName(scope) ++ "] "
        else
            "[" ++ lpfx ++ "] "
    else if (scope != .default)
        "[" ++ @tagName(scope) ++ "] "
    else
        "";

    switch (color) {
        inline else => |col| {
            const lvl_prefix = comptime if (col) switch (level) {
                .debug => "\x1b[1;34mD:\x1b[0m ",
                .info => "\x1b[1;32mI:\x1b[0m ",
                .warn => "\x1b[1;33mW:\x1b[0m ",
                .err => "\x1b[1;31mE:\x1b[0m ",
            } else switch (level) {
                .debug => "D: ",
                .info => "I: ",
                .warn => "W: ",
                .err => "E: ",
            };

            logfile.writer().print(scope_prefix ++ lvl_prefix ++ fmt ++ "\n", args) catch {};
        },
    }
}
