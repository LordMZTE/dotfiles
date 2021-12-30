// zig build-exe -lc -lX11 -lXinerama randomwallpaper.zig && mv randomwallpaper ~/.local/bin
const std = @import("std");
const mem = std.mem;
const c = @cImport({
    @cInclude("X11/Xlib.h");
    @cInclude("X11/extensions/Xinerama.h");
});
const Display = c.struct__XDisplay;

pub fn main() !void {
    var alloc = std.heap.GeneralPurposeAllocator(.{}){};
    if (c.XOpenDisplay(null)) |display| {
        defer _ = c.XCloseDisplay(display);

        var dummy1: c_int = undefined;
        var dummy2: c_int = undefined;
        if (c.XineramaQueryExtension(display, &dummy1, &dummy2) != 0 and c.XineramaIsActive(display) != 0) {
            try updateWallpapers(display, alloc.allocator());
        } else {
            return error.@"No Xinerama!";
        }
    }
}

fn updateWallpapers(display: *Display, alloc: mem.Allocator) !void {
    var heads: c_int = 0;
    const info = c.XineramaQueryScreens(display, &heads);
    defer _ = c.XFree(info);

    var children = try alloc.alloc(*std.ChildProcess, @intCast(usize, heads));
    defer alloc.free(children);

    var i: usize = 0;
    while (i < heads) {
        const head = info[i];

        std.log.info("Setting wallpaper for screen {} with size {}x{}\n", .{ i, head.width, head.height });

        var buf: [10]u8 = undefined;

        const args = [_][]const u8{ "nitrogen", "--random", "--set-scaled", try std.fmt.bufPrint(&buf, "--head={}", .{i}) };
        var child = try std.ChildProcess.init(&args, alloc);
        try child.spawn();

        children[i] = child;

        i += 1;
    }

    for (children) |child| {
        _ = try child.wait();
    }

    for (children) |child| {
        child.deinit();
    }
}
