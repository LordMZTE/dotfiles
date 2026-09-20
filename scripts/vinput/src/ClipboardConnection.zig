//! This structure is self-referential and must not be moved before `deinit` is called.

const std = @import("std");
const wayland = @import("wayland");
const wl = wayland.client.wl;
const ext = wayland.client.ext;

const log = std.log.scoped(.wayland_clipboard);

alloc: std.mem.Allocator,
io: std.Io,
display: *wl.Display,
seat: *wl.Seat,
dcm: *ext.DataControlManagerV1,
datadev: *ext.DataControlDeviceV1,
offers: std.DoublyLinkedList,
current_selection: ?*DataOffer,

const ClipboardConnection = @This();

const GlobalCollector = struct {
    seat: ?*wl.Seat,
    dcm: ?*ext.DataControlManagerV1,
};

const DataOffer = struct {
    node: std.DoublyLinkedList.Node,
    wl: *ext.DataControlOfferV1,
    format_buf: [512]u8,
    format: ?[:0]const u8, // points into format_buf
};

pub fn init(self: *ClipboardConnection, alloc: std.mem.Allocator, io: std.Io) !void {
    const dpy = try wl.Display.connect(null);
    errdefer dpy.disconnect();

    const registry = try dpy.getRegistry();
    defer registry.destroy();

    var globals = GlobalCollector{
        .seat = null,
        .dcm = null,
    };

    registry.setListener(*GlobalCollector, registryListener, &globals);

    log.info("beginning initial display roundtrip", .{});
    if (dpy.roundtrip() != .SUCCESS) return error.RoundtripFail;

    const seat = globals.seat orelse return error.MissingGlobal;
    errdefer seat.destroy();
    const dcm = globals.dcm orelse return error.MissingGlobal;
    errdefer dcm.destroy();

    const datadev = try dcm.getDataDevice(seat);
    errdefer datadev.destroy();

    self.* = .{
        .alloc = alloc,
        .io = io,
        .display = dpy,
        .seat = seat,
        .dcm = dcm,
        .datadev = datadev,
        .offers = .{},
        .current_selection = null,
    };

    datadev.setListener(*ClipboardConnection, datadevListener, self);
}

pub fn deinit(self: *ClipboardConnection) void {
    self.seat.destroy();
    self.dcm.destroy();
    self.datadev.destroy();

    // no need to check self.current_selection which always points into self.offers, which we've
    // freed.
    var maybe_node = self.offers.first;
    while (maybe_node) |node| {
        maybe_node = node.next;
        const offer: *DataOffer = @fieldParentPtr("node", node);

        offer.wl.destroy();
        self.alloc.destroy(offer);
    }

    self.display.disconnect();
    self.* = undefined;
}

pub fn getContent(self: *ClipboardConnection, out_fd: std.posix.fd_t) !void {
    // roundtrip to receive most recent offers
    if (self.display.roundtrip() != .SUCCESS) return error.RoundtripFail;

    const sel = self.current_selection orelse
        // no offer, no need to write anything
        return;

    const mime = sel.format orelse {
        log.warn("got offer without text mime type", .{});
        return;
    };

    sel.wl.receive(mime, out_fd);
    if (self.display.roundtrip() != .SUCCESS) return error.RoundtripFail;
}

const SourceState = struct {
    io: std.Io,
    /// Data to send to a client
    data: []const u8,
    /// Set to true once this source has been replaced
    closed: bool,
};

pub fn serveContent(self: *ClipboardConnection, data: []const u8) !void {
    const src = try self.dcm.createDataSource();
    errdefer src.destroy();

    src.offer("text/plain");
    src.offer("text/plain;charset=utf-8");
    src.offer("TEXT");
    src.offer("STRING");
    src.offer("UTF8_STRING");
    self.datadev.setSelection(src);

    var state: SourceState = .{
        .io = self.io,
        .data = data,
        .closed = false,
    };
    src.setListener(*SourceState, sourceListener, &state);

    while (!state.closed) {
        if (self.display.dispatch() != .SUCCESS) return error.RoundtripFail;
    }
}

fn registryListener(reg: *wl.Registry, event: wl.Registry.Event, globals: *GlobalCollector) void {
    switch (event) {
        .global => |glob| {
            inline for (std.meta.fields(GlobalCollector)) |f| {
                const Interface = @typeInfo(@typeInfo(f.type).optional.child).pointer.child;
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

fn datadevListener(
    _: *ext.DataControlDeviceV1,
    event: ext.DataControlDeviceV1.Event,
    self: *ClipboardConnection,
) void {
    switch (event) {
        .data_offer => |ev| {
            const offer = self.alloc.create(DataOffer) catch @panic("OOM");
            offer.* = .{
                .node = .{},
                .wl = ev.id,
                .format_buf = undefined,
                .format = null,
            };
            self.offers.append(&offer.node);
            offer.wl.setListener(*DataOffer, offerListener, offer);
        },
        .selection => |ev| {
            if (self.current_selection) |prev| {
                self.offers.remove(&prev.node);
                prev.wl.destroy();
                self.alloc.destroy(prev);
                self.current_selection = null;
            }

            if (ev.id == null) return; // only remove old selection

            var maybe_node = self.offers.first;
            while (maybe_node) |node| : (maybe_node = node.next) {
                const offer: *DataOffer = @fieldParentPtr("node", node);

                if (offer.wl == ev.id) {
                    self.current_selection = offer;
                    break;
                }
            }
        },
        .primary_selection => |ev| {
            // since we don't care about the primary selection, we simply remove any offers
            // immediately as they won't be relevant.
            if (ev.id == null) return;

            var maybe_node = self.offers.first;
            while (maybe_node) |node| : (maybe_node = node.next) {
                const offer: *DataOffer = @fieldParentPtr("node", node);

                if (offer.wl == ev.id) {
                    self.offers.remove(node);
                    offer.wl.destroy();
                    self.alloc.destroy(offer);
                    break;
                }
            }
        },
        else => {},
    }
}

fn offerListener(
    _: *ext.DataControlOfferV1,
    event: ext.DataControlOfferV1.Event,
    self: *DataOffer,
) void {
    const text_types = std.StaticStringMap(void).initComptime(.{
        .{ "TEXT", {} },
        .{ "STRING", {} },
        .{ "UTF8_STRING", {} },
    });

    switch (event) {
        .offer => |o| {
            if (self.format) |current_type| {
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
                if (mimetype.len > self.format_buf.len - 1) {
                    log.err("got humungous MIME type, skipping", .{});
                    return;
                }

                @memcpy(self.format_buf[0..mimetype.len], mimetype);
                self.format_buf[mimetype.len] = 0;
                self.format = self.format_buf[0..mimetype.len :0];
            }
        },
    }
}

fn sourceListener(
    _: *ext.DataControlSourceV1,
    event: ext.DataControlSourceV1.Event,
    state: *SourceState,
) void {
    switch (event) {
        .send => |ev| {
            log.info("sending data", .{});
            var file = std.Io.File{ .handle = ev.fd, .flags = .{ .nonblocking = false } };
            defer file.close(state.io);
            var writer = file.writerStreaming(state.io, &.{});
            writer.interface.writeAll(state.data) catch |e| {
                log.err("unable to send clipboard content: {}", .{e});
            };
        },
        .cancelled => state.closed = true,
    }
}

fn roundtrip(self: *const ClipboardConnection) !void {
    if (self.display.roundtrip() != .SUCCESS) return error.RoundtripFail;
}
