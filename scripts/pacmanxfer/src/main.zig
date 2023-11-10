const std = @import("std");
const at = @import("ansi-term");

const Downloader = enum {
    rsync,
    curl,

    fn forProtocol(proto: []const u8) ?Downloader {
        return if (std.mem.eql(u8, proto, "rsync"))
            .rsync
        else if (std.mem.eql(u8, proto, "https") or std.mem.eql(u8, proto, "http"))
            .curl
        else
            null;
    }

    fn getOutputLineCount(self: Downloader) usize {
        return switch (self) {
            .rsync => 2,
            .curl => 3,
        };
    }
};

pub fn main() !u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    if (std.os.argv.len != 3)
        return error.InvalidArguments;

    const url_arg = std.mem.span(std.os.argv[1]);
    const dest = std.mem.span(std.os.argv[2]);

    const url = try std.Uri.parse(url_arg);

    const downloader = Downloader.forProtocol(url.scheme) orelse return error.UnknownProtocol;

    const argv = switch (downloader) {
        .rsync => try alloc.dupe([]const u8, &.{
            "rsync",
            "--copy-links", // needed to correctly download pacman databases
            "--partial",
            "--info=progress2",
            url_arg,
            dest,
        }),
        // zig fmt: off
        .curl => try alloc.dupe([]const u8, &.{
            "curl",
            "--location", // handle redirects
            "--continue-at", "-", // resume partial downloads
            "--fail", // fail fast
            "--output", dest,
            url_arg,
        }),
        // zig fmt: on
    };
    defer alloc.free(argv);

    var stdout = std.io.bufferedWriter(std.io.getStdOut().writer());

    var style: ?at.style.Style = null;
    try updateStyle(stdout.writer(), &style, .{
        .foreground = switch (downloader) {
            .curl => .Red,
            .rsync => .Blue,
        },
        .font_style = .{ .bold = true },
    });
    try stdout.writer().writeAll("==> ");
    try updateStyle(stdout.writer(), &style, .{});
    try stdout.writer().writeAll(std.fs.path.basename(url.path));
    try stdout.writer().writeByte('\n');
    try updateStyle(stdout.writer(), &style, .{
        .foreground = .Green,
        .font_style = .{ .bold = true },
    });
    try stdout.writer().writeAll(">> ");
    try updateStyle(stdout.writer(), &style, .{});
    try stdout.writer().writeAll(url_arg);
    try stdout.writer().writeByte('\n');

    try stdout.flush();

    var child = std.process.Child.init(argv, alloc);
    const term = try child.spawnAndWait();

    const retcode = switch (term) {
        .Exited => |t| t,
        .Signal, .Stopped, .Unknown => 255,
    };

    if (retcode == 0) {
        try at.cursor.cursorUp(stdout.writer(), downloader.getOutputLineCount() + 1);
        try at.clear.clearFromCursorToScreenEnd(stdout.writer());
        try stdout.flush();
    }

    return retcode;
}

fn updateStyle(writer: anytype, old: *?at.style.Style, new: at.style.Style) !void {
    try at.format.updateStyle(writer, new, old.*);
    old.* = new;
}
