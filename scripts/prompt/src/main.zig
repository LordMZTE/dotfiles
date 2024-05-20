const std = @import("std");
const ViMode = @import("vi_mode.zig").ViMode;
const Shell = @import("shell.zig").Shell;
const prompt = @import("prompt.zig");

pub const std_options = std.Options{
    .log_level = .debug,
    .logFn = @import("common").logFn,
};

pub fn main() !void {
    if (std.os.argv.len < 2)
        return error.NotEnoughArguments;

    const verb = std.mem.span(std.os.argv[1]);

    const stdout = std.io.getStdOut();
    if (std.mem.eql(u8, verb, "setup")) {
        if (std.os.argv.len < 3)
            return error.NotEnoughArguments;

        const shell = std.meta.stringToEnum(Shell, std.mem.span(std.os.argv[2])) orelse
            return error.InvalidShell;

        var stdout_buf = std.io.bufferedWriter(stdout.writer());
        try shell.writeInitCode(std.mem.span(std.os.argv[0]), stdout_buf.writer());
        try stdout_buf.flush();
    } else if (std.mem.eql(u8, verb, "show")) {
        const options = prompt.Options{
            .status = try std.fmt.parseInt(
                i32,
                std.posix.getenv("MZPROMPT_STATUS") orelse
                    return error.MissingEnv,
                10,
            ),
            .mode = ViMode.parse(
                std.posix.getenv("MZPROMPT_VI_MODE") orelse
                    return error.MissingEnv,
            ),
            .duration = try std.fmt.parseInt(
                u32,
                std.posix.getenv("MZPROMPT_DURATION") orelse
                    return error.MissingEnv,
                10,
            ),
            .jobs = try std.fmt.parseInt(
                u32,
                std.posix.getenv("MZPROMPT_JOBS") orelse
                    return error.MissingEnv,
                10,
            ),
            .nix_name = @import("nix.zig").findNixShellName(),
            .shell = std.meta.stringToEnum(Shell, std.posix.getenv(
                "MZPROMPT_SHELL",
            ) orelse return error.MissingEnv) orelse return error.InvalidShell,
        };

        var buf: [1024 * 8]u8 = undefined;
        var fbs = std.io.fixedBufferStream(&buf);
        prompt.render(fbs.writer(), options) catch |e| {
            fbs.reset();
            fbs.writer().print("Render Error: {s}\n|> ", .{@errorName(e)}) catch
                @panic("emergency prompt failed to print");
        };
        try stdout.writeAll(fbs.getWritten());
    } else {
        return error.UnknownCommand;
    }
}
