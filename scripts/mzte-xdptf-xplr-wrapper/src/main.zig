const std = @import("std");
const common = @import("common");
const cg = @import("cg");

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();

    var args = try init.minimal.args.iterateAllocator(init.gpa);
    defer args.deinit();

    _ = args.next() orelse return error.InvalidArgs;
    const flags = BoolFlags.readFromArgs(&args) orelse return error.InvalidArgs;
    const path = try arena.dupe(u8, args.next() orelse return error.InvalidArgs);
    const out = try arena.dupe(u8, args.next() orelse return error.InvalidArgs);

    const xplr_cmd = try arena.print("xplr {s}{f} > {f}", .{
        if (flags.directory) "--print-directory-as-result " else "",
        common.fmt.command(&.{path}),
        common.fmt.command(&.{out}),
    });

    var title_buf: [BoolFlags.title_max_len]u8 = undefined;
    // Can't fail because buf is big enough.
    const title = flags.mkTitle(&title_buf) catch unreachable;

    return std.process.replace(init.io, .{
        .argv = &.{
            // TODO: this only works with foot, because other terms likely expect different args.
            cg.term.command,
            "--title",
            title,
            "--",
            "sh",
            "-c",
            xplr_cmd,
        },
    });
}

const BoolFlags = struct {
    /// Choose multiple files
    multiple: bool,
    /// Choose a directory
    directory: bool,
    /// Save a file rather than opening one
    save: bool,

    const title_max_len = 64;

    fn readFromArgs(iter: *std.process.Args.Iterator) ?BoolFlags {
        return .{
            .multiple = getBoolArg(iter.next() orelse return null),
            .directory = getBoolArg(iter.next() orelse return null),
            .save = getBoolArg(iter.next() orelse return null),
        };
    }

    fn getBoolArg(arg: []const u8) bool {
        return std.mem.eql(u8, arg, "1");
    }

    /// Make a title for the terminal window we'll open.
    /// If `buf` is at least `title_max_len` long, will never return an error.
    fn mkTitle(self: BoolFlags, buf: []u8) error{NoSpaceLeft}![]u8 {
        // Must never be longer than title_max_len!
        return std.fmt.bufPrint(buf, "XDP Filechooser [{s}{s}{s}]", .{
            if (self.multiple) "M" else "",
            if (self.directory) "D" else "",
            if (self.save) "S" else "",
        });
    }
};
