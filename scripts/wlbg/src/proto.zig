const std = @import("std");
const builtin = @import("builtin");
const c = ffi.c;

const ffi = @import("ffi.zig");

const State = @import("State.zig");

const cmsghdr = extern struct {
    cmsg_len: usize,
    cmsg_level: i32,
    cmsg_type: i32,
};

// All the structs starting with Swww* represent some swww IPC data type as represented by the wire
// protocol.
const SwwwTransition = packed struct {
    transition_type: enum(u8) { simple, fade, outer, wipe, grow, wave, none },
    duration: f32,
    step: u8, // nonzero
    fps: u16,
    angle: f64,
    pos_x_type: enum(u8) { pixel, percent },
    pos_x: f32,
    pos_y_type: enum(u8) { pixel, percent },
    pos_y: f32,
    bezier0: f32,
    bezier1: f32,
    bezier2: f32,
    bezier3: f32,
    wave0: f32,
    wave1: f32,
    invert_y: u8, // boolean
};

comptime {
    std.debug.assert(@bitSizeOf(SwwwTransition) / 8 == 51);
}

pub fn randomizeWallpapers(state: *State) !void {
    const memfd = try std.posix.memfd_create("swww-ipc", 0);
    defer std.posix.close(memfd);

    const addr = try std.net.Address.initUnix(state.sockpath);

    const sock = try std.posix.socket(std.posix.AF.UNIX, std.posix.SOCK.STREAM, 0);
    defer std.posix.close(sock);

    try std.posix.connect(sock, &addr.any, addr.getOsSockLen());

    var ancillary_buf: [@sizeOf(cmsghdr) + @sizeOf(std.posix.fd_t)]u8 = undefined;

    std.mem.bytesAsValue(cmsghdr, ancillary_buf[0..@sizeOf(cmsghdr)]).* = .{
        .cmsg_len = ancillary_buf.len,
        .cmsg_level = std.os.linux.SOL.SOCKET,
        .cmsg_type = 0x01, // SCM_RIGHTS
    };

    // no padding needed on x86_64
    std.mem.bytesAsValue(std.posix.fd_t, ancillary_buf[@sizeOf(cmsghdr)..]).* = memfd;

    var iov_data = [_]u8{0} ** 16;
    std.mem.bytesAsValue(u32, iov_data[0..8]).* = 3; // "code", 3 for img command

    {
        // shm data layout:
        // 0-50: SwwwTransition
        // 51: number of following ImgReqs
        // ImgReqs

        const mfdwriter = (std.fs.File{ .handle = memfd }).writer();
        var count_writer = std.io.countingWriter(mfdwriter);
        var bufw = std.io.bufferedWriter(count_writer.writer());
        const wr = bufw.writer();

        try wr.writeAll(std.mem.toBytes(SwwwTransition{
            .transition_type = .wipe,
            .duration = 1.0,
            .step = 90,
            .fps = 25,
            .angle = state.rand.random().float(f64) * 360.0,
            .pos_x_type = .percent,
            .pos_x = 0.5,
            .pos_y_type = .percent,
            .pos_y = 0.5,
            .bezier0 = 0.15,
            .bezier1 = 0.85,
            .bezier2 = 0.85,
            .bezier3 = 0.15,
            .wave0 = 0.0,
            .wave1 = 0.0,
            .invert_y = @intFromBool(false),
        })[0..(@bitSizeOf(SwwwTransition) / 8)]);

        try wr.writeByte(@truncate(state.outputs.items.len));

        for (state.outputs.items) |outp| {
            if (outp.name == null) {
                std.log.warn("an output has not received a name from the compositor yet! skipping wallpaper randomization!", .{});
                return;
            }

            const imgpath = state.wps[state.rand.random().uintLessThan(usize, state.wps.len)];

            std.log.info("new wallpaper for output {s}: {s}", .{ outp.name.?, imgpath });

            // TODO TODO TODO TODO TODO
            //  _____ ___  ____   ___
            // |_   _/ _ \|  _ \ / _ \
            //   | || | | | | | | | | |
            //   | || |_| | |_| | |_| |
            //   |_| \___/|____/ \___/
            // TODO TODO TODO TODO TODO
            // USE LITERALLY ANYTHING EXCEPT GDK-PIXBUF!!
            const pixbuf = pixbuf: {
                var gerr: ?*c.GError = null;
                const pixbuf_unscaled = c.gdk_pixbuf_new_from_file(imgpath.ptr, &gerr);
                try ffi.checkGError(gerr);
                defer c.gdk_pixbuf_unref(pixbuf_unscaled);

                break :pixbuf c.gdk_pixbuf_scale_simple(pixbuf_unscaled, outp.width, outp.height, c.GDK_INTERP_BILINEAR);
            };
            defer c.gdk_pixbuf_unref(pixbuf);

            // File Name (why does it need this?)
            try writeString(wr, imgpath);

            // Image Data
            // TODO: swww technically supports the ARGB pixel format, but this always lead to broken
            // images. The CLI seems to query the format from the daemon and convert to that, which
            // is fundamentally different than what we're doing. Somehow, changing from an opaque
            // background to a transparent one keeps the transparent one below that when using the
            // CLI, whereas you'd expect the previous one to be overridden. No idea how that works.
            if (c.gdk_pixbuf_get_has_alpha(pixbuf) != 0) {
                // Ignore alpha component
                std.debug.assert(c.gdk_pixbuf_get_n_channels(pixbuf) == 4);
                var pixels: []u8 = undefined;
                var pixel_len: c.guint = 0;
                pixels.ptr = c.gdk_pixbuf_get_pixels_with_length(pixbuf, &pixel_len);
                pixels.len = pixel_len;

                try wr.writeAll(&std.mem.toBytes(@as(u32, @truncate(pixels.len / 4 * 3))));

                // This is RGBA
                for (0..(pixels.len / 4)) |pixeli| {
                    const i = pixeli * 4;

                    try wr.writeAll(pixels[i..][0..3]);
                }

                std.log.debug("{}x{}, {}", .{ c.gdk_pixbuf_get_width(pixbuf), c.gdk_pixbuf_get_height(pixbuf), pixels.len });
            } else {
                const pixbuflen = c.gdk_pixbuf_get_byte_length(pixbuf);
                try writeString(wr, c.gdk_pixbuf_read_pixels(pixbuf)[0..pixbuflen]);
            }

            // Size
            try wr.writeAll(&std.mem.toBytes(@as(u32, @intCast(c.gdk_pixbuf_get_width(pixbuf)))));
            try wr.writeAll(&std.mem.toBytes(@as(u32, @intCast(c.gdk_pixbuf_get_height(pixbuf)))));

            // Pixel format.
            // See: https://github.com/LGFae/swww/blob/main/common/src/ipc/types.rs#L550-L554
            try wr.writeByte(1);

            // Number of outputs to set this image for. Since we're using different images for each,
            // this is always 1.
            try wr.writeByte(1);

            // Name of the output
            try writeString(wr, outp.name.?);

            // No animation
            try wr.writeByte(0);
        }

        try bufw.flush();
        std.mem.bytesAsValue(u32, iov_data[8..]).* = @truncate(count_writer.bytes_written); // length of shmfd
    }

    std.debug.assert(try std.posix.sendmsg(sock, &.{
        .name = null,
        .namelen = 0,
        .iov = &.{.{ .base = &iov_data, .len = iov_data.len }},
        .iovlen = 1,
        .control = &ancillary_buf,
        .controllen = @truncate(ancillary_buf.len),
        .flags = 0,
    }, 0) == 16);

    var resp_buf: [1024]u8 = undefined;
    const read = try std.posix.read(sock, &resp_buf);
    if (read < 8 or std.mem.bytesToValue(u32, resp_buf[0..read][0..8]) != 5) {
        std.log.warn("daemon sent bad response to img command", .{});
    }
}

// Writes the length of the given data as NE u32, then the data.
fn writeString(writer: anytype, data: []const u8) !void {
    try writer.writeAll(&std.mem.toBytes(@as(u32, @truncate(data.len))));
    try writer.writeAll(data);
}
