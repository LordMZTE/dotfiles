const std = @import("std");
const args = @import("args");
const common = @import("common");

pub const std_options = std.Options{
    .logFn = common.logFn,
};

pub fn main(init: std.process.Init) !u8 {
    const opts = args.parseForCurrentProcess(struct {
        @"no-sysfs": bool = false,
        @"no-ddc": bool = false,

        pub const shorthands = .{
            .s = "no-sysfs",
            .d = "no-ddc",
        };
    }, init, .print) catch return 1;
    defer opts.deinit();

    if (opts.positionals.len != 1) {
        std.log.err("expected one positional argument, got {}", .{opts.positionals.len});
        return 1;
    }

    const brightness = std.fmt.parseInt(u8, opts.positionals[0], 10) catch {
        std.log.err("brightness is not a valid 8-bit integer", .{});
        return 1;
    };

    if (!opts.options.@"no-sysfs") try @import("sysfs.zig").setBrightness(init.io, init.gpa, brightness);
    if (!opts.options.@"no-ddc") try @import("ddc.zig").setBrightness(init.io, init.gpa, brightness);

    return 0;
}
