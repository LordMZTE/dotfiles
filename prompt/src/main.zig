const std = @import("std");
const FishMode = @import("FishMode.zig");
const prompt = @import("prompt.zig");

const fish_code =
    \\functions -e fish_mode_prompt
    \\function fish_prompt
    \\    {s} show $status $fish_bind_mode
    \\end
;

pub fn main() !void {
    if (std.os.argv.len < 2)
        return error.NotEnoughArguments;

    if (std.cstr.cmp(std.os.argv[1], "printfish") == 0) {
        const stdout = std.io.getStdOut();
        try stdout.writer().print(fish_code ++ "\n", .{std.os.argv[0]});
    } else if (std.cstr.cmp(std.os.argv[1], "show") == 0) {
        if (std.os.argv.len < 4)
            return error.NotEnoughArguments;

        const status = try std.fmt.parseInt(i16, std.mem.sliceTo(std.os.argv[2], 0), 10);
        const mode = FishMode.parse(std.mem.sliceTo(std.os.argv[3], 0));
        try prompt.render(std.io.getStdOut().writer(), status, mode);
    } else {
        return error.UnknownCommand;
    }
}
