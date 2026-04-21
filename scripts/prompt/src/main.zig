const std = @import("std");
const ViMode = @import("vi_mode.zig").ViMode;
const Shell = @import("shell.zig").Shell;
const prompt = @import("prompt.zig");

pub const std_options = std.Options{
    .log_level = .debug,
    .logFn = @import("common").logFn,
};

pub fn main(init: std.process.Init) !void {
    const argv = init.minimal.args.vector;

    if (argv.len < 2)
        return error.NotEnoughArguments;

    const verb = std.mem.span(argv[1]);

    var stdout_buf: [1024]u8 = undefined;
    var stdout = std.Io.File.stdout().writer(init.io, &stdout_buf);

    if (std.mem.eql(u8, verb, "setup")) {
        if (argv.len < 3)
            return error.NotEnoughArguments;

        const shell = std.meta.stringToEnum(Shell, std.mem.span(argv[2])) orelse
            return error.InvalidShell;

        try shell.writeInitCode(std.mem.span(argv[0]), &stdout.interface);
        try stdout.interface.flush();
    } else if (std.mem.eql(u8, verb, "show")) {
        const options = prompt.Options{
            .status = try std.fmt.parseInt(
                i32,
                init.environ_map.get("MZPROMPT_STATUS") orelse
                    return error.MissingEnv,
                10,
            ),
            .mode = ViMode.parse(
                init.environ_map.get("MZPROMPT_VI_MODE") orelse
                    return error.MissingEnv,
            ),
            .duration = try std.fmt.parseInt(
                u32,
                init.environ_map.get("MZPROMPT_DURATION") orelse
                    return error.MissingEnv,
                10,
            ),
            .jobs = try std.fmt.parseInt(
                u32,
                init.environ_map.get("MZPROMPT_JOBS") orelse
                    return error.MissingEnv,
                10,
            ),
            .nix_name = @import("nix.zig").findNixShellName(init.environ_map),
            .shell = std.meta.stringToEnum(Shell, init.environ_map.get(
                "MZPROMPT_SHELL",
            ) orelse return error.MissingEnv) orelse return error.InvalidShell,
        };

        prompt.render(init.io, init.environ_map, &stdout.interface, options) catch |e| {
            stdout.interface.end = 0;
            stdout.interface.print("Render Error: {s}\n|> ", .{@errorName(e)}) catch
                @panic("emergency prompt failed to print");
        };
        try stdout.interface.flush();
    } else {
        return error.UnknownCommand;
    }
}
