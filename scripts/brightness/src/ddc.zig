const std = @import("std");
const c = ffi.c;

const ffi = @import("ffi.zig");

const log = std.log.scoped(.ddc);

const brightness_featurecode: c.DDCA_Vcp_Feature_Code = 0x10;
const brightness_maxvalue: u8 = 100;

pub fn setBrightness(alloc: std.mem.Allocator, brightness: u8) !void {
    _ = alloc;
    log.info("ddcutil {s}", .{c.ddca_ddcutil_extended_version_string()});
    try ffi.checkDDCAError(c.ddca_init2(
        "",
        c.DDCA_SYSLOG_INFO,
        c.DDCA_INIT_OPTIONS_NONE,
        null,
    ));

    var displays: ?*c.DDCA_Display_Info_List = null;
    try ffi.checkDDCAError(c.ddca_get_display_info_list2(false, &displays));
    defer c.ddca_free_display_info_list(displays);

    const brightness_scaled: u8 = @intCast((@as(u16, brightness) * brightness_maxvalue) / 255);

    for (displays.?.info()[0..@intCast(displays.?.ct)]) |dpyinf| {
        setOne(brightness_scaled, dpyinf) catch |e| {
            log.err("fail: {t}", .{e});
        };
    }
}

fn setOne(brightness_scaled: u8, dpyinf: c.DDCA_Display_Info) !void {
    log.info("setting {f}", .{fmtIOPath(dpyinf.path)});

    var dpy: c.DDCA_Display_Handle = undefined;
    try ffi.checkDDCAError(c.ddca_open_display2(dpyinf.dref, false, &dpy));
    defer _ = c.ddca_close_display(dpy);

    try ffi.checkDDCAError(c.ddca_set_non_table_vcp_value(dpy, brightness_featurecode, 0, brightness_scaled));
}

fn fmtIOPath(iop: c.DDCA_IO_Path) std.fmt.Alt(c.DDCA_IO_Path, fmtIOPathFn) {
    return .{ .data = iop };
}

fn fmtIOPathFn(iop: c.DDCA_IO_Path, writer: *std.Io.Writer) std.Io.Writer.Error!void {
    switch (iop.io_mode) {
        c.DDCA_IO_I2C => {
            try writer.print("[I2C {}]", .{iop.path.i2c_busno});
        },
        c.DDCA_IO_USB => {
            try writer.print("[USB {}]", .{iop.path.hiddev_devno});
        },
        else => unreachable,
    }
}
