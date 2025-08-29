const std = @import("std");
const args = @import("args");
const common = @import("common");

pub const std_options = std.Options{
    .logFn = common.logFn,
};

pub fn main() !u8 {
    const alloc = std.heap.c_allocator;
    const opts = args.parseForCurrentProcess(struct {
        @"no-sysfs": bool = false,
        @"no-ddc": bool = false,

        pub const shorthands = .{
            .s = "no-sysfs",
            .d = "no-ddc",
        };
    }, alloc, .print) catch return 1;
    defer opts.deinit();

    if (opts.positionals.len != 1) {
        std.log.err("expected one positional argument, got {}", .{opts.positionals.len});
        return 1;
    }

    const brightness = std.fmt.parseInt(u8, opts.positionals[0], 10) catch {
        std.log.err("brightness is not a valid 8-bit integer", .{});
        return 1;
    };

    if (!opts.options.@"no-sysfs") try @import("sysfs.zig").setBrightness(alloc, brightness);
    if (!opts.options.@"no-ddc") try @import("ddc.zig").setBrightness(alloc, brightness);

    return 0;
}
