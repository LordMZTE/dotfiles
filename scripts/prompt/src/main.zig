const std = @import("std");
const FishMode = @import("FishMode.zig");
const prompt = @import("prompt.zig");

const fish_code =
    \\functions -e fish_mode_prompt
    \\function fish_prompt
    \\    set -x MZPROMPT_STATUS $status
    \\    set -x MZPROMPT_FISH_MODE $fish_bind_mode
    \\    set -x MZPROMPT_DURATION $CMD_DURATION
    \\    set -x MZPROMPT_JOBS (count (jobs))
    \\    {s} show
    \\end
;

pub fn main() !void {
    if (std.os.argv.len < 2)
        return error.NotEnoughArguments;

    const verb = std.mem.span(std.os.argv[1]);

    if (std.mem.eql(u8, verb, "printfish")) {
        const stdout = std.io.getStdOut();
        try stdout.writer().print(fish_code ++ "\n", .{std.os.argv[0]});
    } else if (std.mem.eql(u8, verb, "show")) {
        const options = prompt.Options{
            .status = try std.fmt.parseInt(
                i16,
                std.os.getenv("MZPROMPT_STATUS") orelse
                    return error.MissingEnv,
                10,
            ),
            .mode = FishMode.parse(
                std.os.getenv("MZPROMPT_FISH_MODE") orelse
                    return error.MissingEnv,
            ),
            .duration = try std.fmt.parseInt(
                u32,
                std.os.getenv("MZPROMPT_DURATION") orelse
                    return error.MissingEnv,
                10,
            ),
            .jobs = try std.fmt.parseInt(
                u32,
                std.os.getenv("MZPROMPT_JOBS") orelse
                    return error.MissingEnv,
                10,
            ),
        };

        var buf = std.BoundedArray(u8, 1024 * 8).init(0) catch unreachable;
        prompt.render(buf.writer(), options) catch |e| {
            buf.resize(0) catch unreachable;
            buf.writer().print("Render Error: {s}\n|> ", .{@errorName(e)}) catch unreachable;
        };
        try std.io.getStdOut().writeAll(buf.slice());
    } else {
        return error.UnknownCommand;
    }
}
