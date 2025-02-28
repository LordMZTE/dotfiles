const std = @import("std");
const builtin = @import("builtin");
const c = ffi.c;
const opts = @import("opts");

const ffi = @import("ffi.zig");

const State = @import("State.zig");

const ctp_base: [3]u8 = blk: {
    const int = std.fmt.parseInt(u24, opts.ctp_base, 16) catch unreachable;
    break :blk .{ int >> 0x10, int >> 0x08 & 0xff, int & 0xff };
};

const cmsghdr = extern struct {
    cmsg_len: usize,
    cmsg_level: i32,
    cmsg_type: i32,
};

const SwwwTransitionType = enum(u8) { simple, fade, outer, wipe, grow, wave, none };

// All the structs starting with Swww* represent some swww IPC data type as represented by the wire
// protocol.
const SwwwTransition = packed struct {
    transition_type: SwwwTransitionType,
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

    fn makeRandom(rand: std.Random) SwwwTransition {
        // We don't want simple or none.
        //const typ: SwwwTransitionType = @enumFromInt(rand.uintLessThan(u8, 5) + 1);
        const typ = .wipe;

        return .{
            .transition_type = typ,

            // Between 1 and 5 seconds
            .duration = 1.0 + rand.float(f32) * 4.0,

            // Only generate this for transitions that use it.
            .angle = switch (typ) {
                .wipe, .wave => rand.float(f64) * 360.0,
                else => 0.0,
            },

            .pos_x = switch (typ) {
                .grow, .outer => rand.float(f32),
                else => 0.0,
            },
            .pos_y = switch (typ) {
                .grow, .outer => rand.float(f32),
                else => 0.0,
            },

            .wave0 = switch (typ) {
                .wave => 10.0 + rand.float(f32) * 20.0,
                else => 0.0,
            },
            .wave1 = switch (typ) {
                .wave => 10.0 + rand.float(f32) * 20.0,
                else => 0.0,
            },

            .bezier0 = 0.15,
            .bezier1 = 0.85,
            .bezier2 = 0.85,
            .bezier3 = 0.15,
            .pos_x_type = .percent,
            .pos_y_type = .percent,
            .step = 90,
            .fps = 25,
            .invert_y = 0,
        };
    }
};

comptime {
    std.debug.assert(@bitSizeOf(SwwwTransition) / 8 == 51);
}

pub const WallpaperMode = enum {
    random,
    dark,
};

pub const QueryAnswer = struct {
    arena: std.heap.ArenaAllocator,
    bgs: []BgInfo,
};

pub const BgInfo = struct {
    name: []u8,
    width: u32,
    height: u32,
    scale_type: ScaleType,
    scale: i32,
    img: BgImg,
    pixfmt: PixelFormat,
};

pub const ScaleType = enum { whole, fractional };

pub const BgImg = union(enum) {
    color: [3]u8,
    img: []const u8, // path, not image data :P
};

// NOTE: you'll notice that some tags here differ from upstream source code. This is because
// upstream code makes literally no sense and I'm relatively sure that they basically *mean*
// the opposite of what this enum would suggest.
pub const PixelFormat = enum(u8) {
    rgb,
    bgr,
    rgba,
    bgra,

    pub fn hasAlpha(self: PixelFormat) bool {
        return switch (self) {
            .abgr, .argb => true,
            .bgr, .rgb => false,
        };
    }

    fn needByteswap(self: PixelFormat) bool {
        return switch (self) {
            .bgr, .abgr => true,
            .rgb, .argb => false,
        };
    }
};

pub fn query(state: *State) !QueryAnswer {
    const sock = try connect(state.sockpath);
    defer std.posix.close(sock);

    // send request
    {
        var iov_data = [_]u8{0} ** 16;
        std.mem.bytesAsValue(u64, iov_data[0..8]).* = 1; // "code", 1 for query
        std.debug.assert(try std.posix.sendmsg(sock, &.{
            .name = null,
            .namelen = 0,
            .iov = &.{.{ .base = &iov_data, .len = iov_data.len }},
            .iovlen = 1,
            .control = null,
            .controllen = 0,
            .flags = 0,
        }, 0) == 16);
    }

    // receive answer
    {
        var iov_data: [16]u8 = undefined;
        var iov = std.posix.iovec{ .base = &iov_data, .len = iov_data.len };
        var ancillary_buf: [@sizeOf(cmsghdr) + @sizeOf(std.posix.fd_t)]u8 = undefined;
        var msg = std.posix.msghdr{
            .name = null,
            .namelen = 0,
            .iov = (&iov)[0..1],
            .iovlen = 1,
            .control = &ancillary_buf,
            .controllen = @truncate(ancillary_buf.len),
            .flags = 0,
        };
        const recvlen = std.os.linux.recvmsg(
            sock,
            &msg,
            // Wait for our (correct-sized) buffers to be filled by the daemon
            std.posix.MSG.WAITALL,
        );
        if (recvlen != iov_data.len or
            msg.iovlen != 1 or
            iov.len != iov_data.len or
            msg.controllen != ancillary_buf.len or
            // "code" for ResInfo
            std.mem.bytesToValue(u64, iov_data[0..8]) != 8) return error.ProtocolViolation;
        const header = std.mem.bytesToValue(cmsghdr, ancillary_buf[0..@sizeOf(cmsghdr)]);
        if (header.cmsg_len != ancillary_buf.len or
            header.cmsg_level != std.os.linux.SOL.SOCKET or
            // SCM_RIGHTS
            header.cmsg_type != 0x01) return error.ProtocolViolation;
        const fd = std.mem.bytesToValue(std.posix.fd_t, ancillary_buf[@sizeOf(cmsghdr)..]);
        defer std.posix.close(fd);

        var buf_reader = std.io.bufferedReader((std.fs.File{ .handle = fd }).reader());
        const r = buf_reader.reader();

        var ret_arena = std.heap.ArenaAllocator.init(state.alloc);
        errdefer ret_arena.deinit();
        const ret_alloc = ret_arena.allocator();

        const n_bgs = try r.readByte();
        const bgs = try ret_alloc.alloc(BgInfo, n_bgs);
        for (0..n_bgs) |i| {
            const name = try readStringAlloc(r, ret_alloc);

            const width = std.mem.bytesToValue(u32, &try r.readBytesNoEof(4));
            const height = std.mem.bytesToValue(u32, &try r.readBytesNoEof(4));

            const scale_type: ScaleType = switch (try r.readByte()) {
                0 => .whole,
                1 => .fractional,
                else => return error.ProtocolViolation,
            };

            const scale = std.mem.bytesToValue(i32, &try r.readBytesNoEof(4));

            const img: BgImg = switch (try r.readByte()) {
                0 => .{ .color = try r.readBytesNoEof(3) },
                1 => .{ .img = try readStringAlloc(r, ret_alloc) },
                else => return error.ProtocolViolation,
            };

            const pixfmt = std.meta.intToEnum(
                PixelFormat,
                try r.readByte(),
            ) catch return error.ProtocolViolation;

            bgs[i] = .{
                .name = name,
                .width = width,
                .height = height,
                .scale_type = scale_type,
                .scale = scale,
                .img = img,
                .pixfmt = pixfmt,
            };
        }
        return .{
            .arena = ret_arena,
            .bgs = bgs,
        };
    }
}

pub fn randomizeWallpapers(state: *State, how: WallpaperMode) !void {
    const quer = try query(state);
    defer quer.arena.deinit();

    const memfd = try std.posix.memfd_create("swww-ipc", 0);
    defer std.posix.close(memfd);

    const sock = try connect(state.sockpath);
    defer std.posix.close(sock);

    var ancillary_buf: [@sizeOf(cmsghdr) + @sizeOf(std.posix.fd_t)]u8 = undefined;

    std.mem.bytesAsValue(cmsghdr, ancillary_buf[0..@sizeOf(cmsghdr)]).* = .{
        .cmsg_len = ancillary_buf.len,
        .cmsg_level = std.os.linux.SOL.SOCKET,
        .cmsg_type = 0x01, // SCM_RIGHTS
    };

    // no padding needed on x86_64
    std.mem.bytesAsValue(std.posix.fd_t, ancillary_buf[@sizeOf(cmsghdr)..]).* = memfd;

    var iov_data = [_]u8{0} ** 16;
    std.mem.bytesAsValue(u64, iov_data[0..8]).* = 3; // "code", 3 for img command

    {
        // shm data layout:
        // 0-50: SwwwTransition
        // 51: number of following ImgReqs
        // ImgReqs

        const mfdwriter = (std.fs.File{ .handle = memfd }).writer();
        var count_writer = std.io.countingWriter(mfdwriter);
        var bufw = std.io.BufferedWriter(
            1024 * 1024, // One MB because we're writing lots of data.
            @TypeOf(count_writer.writer()),
        ){ .unbuffered_writer = count_writer.writer() };
        const wr = bufw.writer();

        try wr.writeAll(std.mem.toBytes(
            SwwwTransition.makeRandom(state.rand.random()),
        )[0..(@bitSizeOf(SwwwTransition) / 8)]);

        try wr.writeByte(@truncate(quer.bgs.len));

        for (quer.bgs) |outp| {
            switch (how) {
                .random => {
                    const imgpath = state.wps[state.rand.random().uintLessThan(usize, state.wps.len)];

                    std.log.info("new wallpaper for output {s}: {s}", .{ outp.name, imgpath });

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

                        // If the size is already correct, no need to rescale and copy the whole buffer.
                        if (c.gdk_pixbuf_get_width(pixbuf_unscaled) == outp.width and
                            c.gdk_pixbuf_get_height(pixbuf_unscaled) == outp.height)
                            break :pixbuf pixbuf_unscaled;

                        defer c.gdk_pixbuf_unref(pixbuf_unscaled);

                        break :pixbuf c.gdk_pixbuf_scale_simple(
                            pixbuf_unscaled,
                            @intCast(outp.width),
                            @intCast(outp.height),
                            c.GDK_INTERP_BILINEAR,
                        );
                    };
                    defer c.gdk_pixbuf_unref(pixbuf);

                    // File Name (why does it need this?)
                    try writeString(wr, imgpath);

                    // Image Data
                    // GDK Pixbuf is always either RGB or RGBA
                    std.log.debug("pixelformat: {}", .{outp.pixfmt});
                    if (c.gdk_pixbuf_get_has_alpha(pixbuf) != 0) {
                        std.debug.assert(c.gdk_pixbuf_get_n_channels(pixbuf) == 4);
                        var pixels: []u8 = undefined;
                        var pixel_len: c.guint = 0;
                        pixels.ptr = c.gdk_pixbuf_get_pixels_with_length(pixbuf, &pixel_len);
                        pixels.len = pixel_len;

                        switch (outp.pixfmt) {
                            .bgra => {
                                try wr.writeAll(&std.mem.toBytes(@as(u32, @truncate(pixels.len))));

                                for (0..(pixels.len / 3)) |pixeli| {
                                    const i = pixeli * 3;

                                    const pix: [4]u8 = .{
                                        pixels[i + 2], pixels[i + 1], pixels[i], pixels[i + 3],
                                    };
                                    try wr.writeAll(&pix);
                                }
                            },
                            .rgba => {
                                try writeString(wr, pixels);
                            },

                            .rgb => {
                                try wr.writeAll(&std.mem.toBytes(@as(u32, @truncate(pixels.len / 4 * 3))));

                                for (0..(pixels.len / 4)) |pixeli| {
                                    const i = pixeli * 4;

                                    try wr.writeAll(pixels[i..][0..3]);
                                }
                            },
                            .bgr => {
                                try wr.writeAll(&std.mem.toBytes(@as(u32, @truncate(pixels.len / 4 * 3))));

                                for (0..(pixels.len / 4)) |pixeli| {
                                    const i = pixeli * 4;

                                    try wr.writeByte(pixels[i + 2]);
                                    try wr.writeByte(pixels[i + 1]);
                                    try wr.writeByte(pixels[i]);
                                }
                            },
                        }
                    } else {
                        const pixbuflen = c.gdk_pixbuf_get_byte_length(pixbuf);
                        const pixels = c.gdk_pixbuf_read_pixels(pixbuf)[0..pixbuflen];

                        switch (outp.pixfmt) {
                            .bgra => {
                                try wr.writeAll(&std.mem.toBytes(@as(u32, @truncate(pixels.len / 3 * 4))));

                                for (0..(pixels.len / 3)) |pixeli| {
                                    const i = pixeli * 3;

                                    const pix: [4]u8 = .{
                                        pixels[i + 2], pixels[i + 1], pixels[i], 0xff,
                                    };
                                    try wr.writeAll(&pix);
                                }
                            },
                            .rgba => {
                                try wr.writeAll(&std.mem.toBytes(@as(u32, @truncate(pixels.len / 3 * 4))));

                                for (0..(pixels.len / 3)) |pixeli| {
                                    const i = pixeli * 3;

                                    const pix: [4]u8 = .{
                                        pixels[i], pixels[i + 1], pixels[i + 2], 0xff,
                                    };
                                    try wr.writeAll(&pix);
                                }
                            },
                            .rgb => {
                                try writeString(wr, pixels);
                            },
                            .bgr => {
                                try wr.writeAll(&std.mem.toBytes(@as(u32, @truncate(pixels.len))));

                                for (0..(pixels.len / 3)) |pixeli| {
                                    const i = pixeli * 3;

                                    const pix: [3]u8 = .{
                                        pixels[i + 2], pixels[i + 1], pixels[i],
                                    };
                                    try wr.writeAll(&pix);
                                }
                            },
                        }
                    }

                    // Size
                    try wr.writeAll(&std.mem.toBytes(@as(u32, @intCast(c.gdk_pixbuf_get_width(pixbuf)))));
                    try wr.writeAll(&std.mem.toBytes(@as(u32, @intCast(c.gdk_pixbuf_get_height(pixbuf)))));
                },
                .dark => {
                    // File Name
                    try writeString(wr, "[dark mode]");

                    // Data (monotone catppuccin base background)
                    switch (outp.pixfmt) {
                        .rgb => {
                            try wr.writeAll(&std.mem.toBytes(@as(u32, @intCast(outp.width * outp.height * ctp_base.len))));
                            try wr.writeBytesNTimes(&ctp_base, outp.width * outp.height);
                        },
                        .bgr => {
                            const color = [3]u8{ctp_base[2], ctp_base[1], ctp_base[0]};
                            try wr.writeAll(&std.mem.toBytes(@as(u32, @intCast(outp.width * outp.height * color.len))));
                            try wr.writeBytesNTimes(&color, outp.width * outp.height);
                        },
                        .rgba => {
                            try wr.writeAll(&std.mem.toBytes(@as(u32, @intCast(outp.width * outp.height * (ctp_base.len + 1)))));
                            try wr.writeBytesNTimes(&ctp_base ++ .{0xff}, outp.width * outp.height);
                        },
                        .bgra => {
                            const color = [4]u8{ctp_base[2], ctp_base[1], ctp_base[0], 0xff};
                            try wr.writeAll(&std.mem.toBytes(@as(u32, @intCast(outp.width * outp.height * color.len))));
                            try wr.writeBytesNTimes(&color, outp.width * outp.height);
                        },
                    }

                    // Size
                    try wr.writeAll(&std.mem.toBytes(@as(u32, outp.width)));
                    try wr.writeAll(&std.mem.toBytes(@as(u32, outp.height)));
                },
            }

            // Pixel format. This NEEDS to be the format advertised by the daemon for the output,
            // otherwise, it segfaults (genious API design, right?)
            try wr.writeByte(@intFromEnum(outp.pixfmt));

            // Number of outputs to set this image for. Since we're using different images for each,
            // this is always 1.
            try wr.writeByte(1);

            // Name of the output
            try writeString(wr, outp.name);

            // No animation
            try wr.writeByte(0);
        }

        try bufw.flush();
        std.mem.bytesAsValue(u64, iov_data[8..]).* = @truncate(count_writer.bytes_written); // length of shmfd
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
    const read = try (std.fs.File{ .handle = sock }).reader().readAll(&resp_buf);
    if (read < 8 or std.mem.bytesToValue(u64, resp_buf[0..read][0..8]) != 5) {
        std.log.warn("daemon sent bad response to img command", .{});
    }
}

fn connect(sockpath: []const u8) !std.posix.fd_t {
    const addr = try std.net.Address.initUnix(sockpath);

    const sock = try std.posix.socket(std.posix.AF.UNIX, std.posix.SOCK.STREAM, 0);
    errdefer std.posix.close(sock);

    try std.posix.connect(sock, &addr.any, addr.getOsSockLen());

    return sock;
}

/// Writes the length of the given data as NE u32, then the data.
fn writeString(writer: anytype, data: []const u8) !void {
    try writer.writeAll(&std.mem.toBytes(@as(u32, @truncate(data.len))));
    try writer.writeAll(data);
}

fn readStringAlloc(reader: anytype, alloc: std.mem.Allocator) ![]u8 {
    const len = std.mem.bytesToValue(u32, &try reader.readBytesNoEof(4));
    const name = try alloc.alloc(u8, len);
    errdefer alloc.free(name);
    try reader.readNoEof(name);

    return name;
}
