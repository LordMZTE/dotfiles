const std = @import("std");
const common = @import("common");

const log = std.log.scoped(.sysfs);

const backlight_sysfsdir = "/sys/class/backlight";

pub fn setBrightness(alloc: std.mem.Allocator, brightness: u8) !void {
    _ = alloc;
    var backlightdir = try std.fs.openDirAbsolute(backlight_sysfsdir, .{
        .iterate = true,
    });
    defer backlightdir.close();

    // Buffer used for file paths and readers.
    var buf: [@max(std.fs.max_path_bytes, 1024 * 4)]u8 = undefined;

    var bldiriter = backlightdir.iterate();
    while (try bldiriter.next()) |ent| {
        if (ent.kind != .directory and ent.kind != .sym_link) continue;

        setOne(&buf, backlightdir, ent.name, brightness) catch |e| {
            log.err("fail: {t}", .{e});
        };
    }
}

fn setOne(buf: []u8, backlightdir: std.fs.Dir, subpath: []const u8, brightness: u8) !void {
    log.info("setting {s}", .{subpath});

    const max = max: {
        const max_subpath = try common.paths.bufJoinZ(buf, &.{ subpath, "max_brightness" });

        var max_file = try backlightdir.openFile(max_subpath, .{});
        defer max_file.close();

        var reader = max_file.reader(buf);

        reader.interface.fill(reader.interface.buffer.len) catch |e| switch (e) {
            error.EndOfStream => {},
            else => |err| return err,
        };

        break :max try std.fmt.parseInt(u32, std.mem.trimEnd(
            u8,
            reader.interface.buffered(),
            &std.ascii.whitespace,
        ), 10);
    };

    const new_brightness = (@as(u32, brightness) * max) / 255;

    const brightness_subpath = try common.paths.bufJoinZ(buf, &.{ subpath, "brightness" });

    var brightness_file = try backlightdir.openFile(brightness_subpath, .{ .mode = .write_only });
    defer brightness_file.close();

    var writer = brightness_file.writer(buf);

    try writer.interface.print("{}", .{new_brightness});
    try writer.interface.flush();
}
