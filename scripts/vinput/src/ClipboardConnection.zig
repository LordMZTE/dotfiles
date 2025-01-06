const std = @import("std");
const wayland = @import("wayland");
const wl = wayland.client.wl;
const xdg = wayland.client.xdg;

const log = std.log.scoped(.wayland_clipboard);

display: *wl.Display,
shm: *wl.Shm,
seat: *wl.Seat,
compositor: *wl.Compositor,
data_device_manager: *wl.DataDeviceManager,
xdg_wm_base: *xdg.WmBase,

const ClipboardConnection = @This();

const GlobalCollector = struct {
    seat: ?*wl.Seat,
    shm: ?*wl.Shm,
    compositor: ?*wl.Compositor,
    data_device_manager: ?*wl.DataDeviceManager,
    xdg_wm_base: ?*xdg.WmBase,
};

const PopupWindow = struct {
    surface: *wl.Surface,
    xdg_surface: *xdg.Surface,
    xdg_toplevel: *xdg.Toplevel,
    shm_pool: *wl.ShmPool,
    shm_buf: *wl.Buffer,

    fn show(cc: *ClipboardConnection) !PopupWindow {
        const surf = try cc.compositor.createSurface();
        errdefer surf.destroy();

        const xdg_surface = try cc.xdg_wm_base.getXdgSurface(surf);
        errdefer xdg_surface.destroy();
        xdg_surface.setListener(*const void, xdgSurfaceConfigureListener, &{});

        const xdg_toplevel = try xdg_surface.getToplevel();
        errdefer xdg_toplevel.destroy();
        xdg_toplevel.setTitle("vinput");

        surf.commit();

        try cc.roundtrip();

        const width = 1;
        const height = 1;
        const stride = width * 4;
        const size = stride * height; // 1x1x4 bytes

        const memfd = try std.posix.memfd_create("surface_shm", 0);
        defer std.posix.close(memfd);
        try std.posix.ftruncate(memfd, size);

        const shm_pool = try cc.shm.createPool(memfd, size);
        errdefer shm_pool.destroy();
        const shm_buf = try shm_pool.createBuffer(0, width, height, stride, .argb8888);
        errdefer shm_buf.destroy();

        surf.attach(shm_buf, 0, 0);
        surf.damage(0, 0, width, height);
        surf.commit();

        try cc.roundtrip();

        return .{
            .surface = surf,
            .xdg_surface = xdg_surface,
            .xdg_toplevel = xdg_toplevel,
            .shm_pool = shm_pool,
            .shm_buf = shm_buf,
        };
    }

    fn deinit(self: PopupWindow) void {
        self.shm_buf.destroy();
        self.shm_pool.destroy();
        self.xdg_toplevel.destroy();
        self.xdg_surface.destroy();
        self.surface.destroy();
    }
};

pub fn init() !ClipboardConnection {
    const dpy = try wl.Display.connect(null);
    errdefer dpy.disconnect();

    const registry = try dpy.getRegistry();
    defer registry.destroy();

    var globals = GlobalCollector{
        .shm = null,
        .seat = null,
        .compositor = null,
        .data_device_manager = null,
        .xdg_wm_base = null,
    };

    registry.setListener(*GlobalCollector, registryListener, &globals);

    log.info("beginning initial display roundtrip", .{});
    if (dpy.roundtrip() != .SUCCESS) return error.RoundtripFail;

    return .{
        .display = dpy,
        .shm = globals.shm orelse return error.MissingGlobal,
        .seat = globals.seat orelse return error.MissingGlobal,
        .compositor = globals.compositor orelse return error.MissingGlobal,
        .data_device_manager = globals.data_device_manager orelse return error.MissingGlobal,
        .xdg_wm_base = globals.xdg_wm_base orelse return error.MissingGlobal,
    };
}

pub fn deinit(self: *ClipboardConnection) void {
    self.shm.destroy();
    self.seat.destroy();
    self.compositor.destroy();
    self.data_device_manager.destroy();
    self.xdg_wm_base.destroy();
    self.display.disconnect();
    self.* = undefined;
}

pub fn getContent(self: *ClipboardConnection, out_fd: std.posix.fd_t) !void {
    const DataDeviceListener = struct {
        out_fd: std.posix.fd_t,
        display: *wl.Display,

        fn onEvent(_: *wl.DataDevice, ev: wl.DataDevice.Event, ddl: *@This()) void {
            switch (ev) {
                .data_offer => |offer| {
                    defer offer.id.destroy();
                    const MimeType = struct {
                        buf: [1024]u8 = undefined,
                        t: ?[:0]const u8 = null,

                        fn offerListener(_: *wl.DataOffer, event: wl.DataOffer.Event, mt: *@This()) void {
                            const text_types = std.StaticStringMap(void).initComptime(.{
                                .{ "TEXT", {} },
                                .{ "STRING", {} },
                                .{ "UTF8_STRING", {} },
                            });

                            switch (event) {
                                .offer => |o| {
                                    if (mt.t) |current_type| {
                                        var buf: [512]u8 = undefined;
                                        const lower_type = std.ascii.lowerString(&buf, current_type);

                                        if (std.mem.containsAtLeast(u8, lower_type, 1, "utf8") or
                                            std.mem.containsAtLeast(u8, lower_type, 1, "utf-8"))
                                        {
                                            // GTK likes to mangle text when a MIME type without UTF-8
                                            // is requested, thus we prefer it.
                                            return;
                                        }
                                    }

                                    const mimetype = std.mem.span(o.mime_type);
                                    if (text_types.has(mimetype) or
                                        std.mem.startsWith(u8, mimetype, "text/"))
                                    {
                                        if (mimetype.len > mt.buf.len - 1) {
                                            log.err("got humungous MIME type, skipping", .{});
                                            return;
                                        }

                                        @memcpy(mt.buf[0..mimetype.len], mimetype);
                                        mt.buf[mimetype.len] = 0;
                                        mt.t = mt.buf[0..mimetype.len :0];
                                    }
                                },

                                else => {},
                            }
                        }
                    };

                    var mime = MimeType{};

                    offer.id.setListener(*MimeType, MimeType.offerListener, &mime);
                    if (ddl.display.dispatch() != .SUCCESS)
                        log.err("dispatch in data offer receive failed", .{});

                    if (mime.t) |mimetype| {
                        log.info("receiving data offer with MIME type {s}", .{mimetype});
                        offer.id.receive(mimetype, ddl.out_fd);
                    } else {
                        log.warn("got data offer with no text MIME type", .{});
                    }
                },

                else => {},
            }
        }
    };
    var ddl = DataDeviceListener{
        .display = self.display,
        .out_fd = out_fd,
    };

    const data_device = try self.data_device_manager.getDataDevice(self.seat);
    defer data_device.release();
    data_device.setListener(*DataDeviceListener, DataDeviceListener.onEvent, &ddl);

    const popup = try PopupWindow.show(self);
    popup.deinit();
    try self.roundtrip();
}

pub fn serveContent(self: *ClipboardConnection, data: []const u8) !void {
    const DataSender = struct {
        data: []const u8,
        data_source: *wl.DataSource,
        device: *wl.DataDevice,
        kb: *wl.Keyboard,
        done: bool = false,

        fn onEvent(_: *wl.DataSource, ev: wl.DataSource.Event, ds: *@This()) void {
            switch (ev) {
                .send => |send| {
                    log.info("sending data", .{});
                    var file = std.fs.File{ .handle = send.fd };
                    defer file.close();
                    file.writeAll(ds.data) catch |e| {
                        log.err("unable to send clipboard content: {}", .{e});
                    };
                },
                .cancelled => {
                    ds.done = true;
                    log.info("done serving data source", .{});
                },
                else => {},
            }
        }

        fn keyboardListener(_: *wl.Keyboard, ev: wl.Keyboard.Event, ds: *@This()) void {
            switch (ev) {
                .enter => |enter| {
                    log.info("got keyboard enter event", .{});
                    ds.device.setSelection(ds.data_source, enter.serial);
                },
                else => {},
            }
        }
    };
    const device = try self.data_device_manager.getDataDevice(self.seat);
    defer device.release();

    const data_source = try self.data_device_manager.createDataSource();
    defer data_source.destroy();
    data_source.offer("text/plain");
    data_source.offer("text/plain;charset=utf-8");
    data_source.offer("TEXT");
    data_source.offer("STRING");
    data_source.offer("UTF8_STRING");

    const kb = try self.seat.getKeyboard();
    defer kb.destroy();

    var data_sender = DataSender{
        .data = data,
        .data_source = data_source,
        .device = device,
        .kb = kb,
    };

    data_source.setListener(*DataSender, DataSender.onEvent, &data_sender);
    kb.setListener(*DataSender, DataSender.keyboardListener, &data_sender);

    // This generates a keyboard enter event, the serial of which we can use to set the selection.
    const popup = try PopupWindow.show(self);
    popup.deinit();

    while (!data_sender.done) {
        if (self.display.dispatch() != .SUCCESS) return error.DispatchFail;
    }
}

fn xdgSurfaceConfigureListener(xdg_surface: *xdg.Surface, ev: xdg.Surface.Event, _: *const void) void {
    xdg_surface.ackConfigure(ev.configure.serial);
}

fn registryListener(reg: *wl.Registry, event: wl.Registry.Event, globals: *GlobalCollector) void {
    switch (event) {
        .global => |glob| {
            inline for (std.meta.fields(GlobalCollector)) |f| {
                const Interface = @typeInfo(@typeInfo(f.type).Optional.child).Pointer.child;
                if (std.mem.orderZ(u8, glob.interface, Interface.interface.name) == .eq) {
                    @field(globals, f.name) = reg.bind(
                        glob.name,
                        Interface,
                        Interface.generated_version,
                    ) catch return;
                    return;
                }
            }
        },
        .global_remove => {},
    }
}

fn roundtrip(self: *const ClipboardConnection) !void {
    if (self.display.roundtrip() != .SUCCESS) return error.RoundtripFail;
}
