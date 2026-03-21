const std = @import("std");
const wayland = @import("wayland");
const common = @import("common");

const wl = wayland.client.wl;
const zriver = wayland.client.zriver;

dpy: *wl.Display,
seat: ?*wl.Seat,
ctl: ?*zriver.ControlV1,

const Connection = @This();

pub fn init() !Connection {
    const dpy = try wl.Display.connect(null);
    errdefer dpy.disconnect();

    const reg = try dpy.getRegistry();
    defer reg.destroy();

    var self = Connection{
        .dpy = dpy,
        .seat = null,
        .ctl = null,
    };

    reg.setListener(*Connection, registryListener, &self);

    if (dpy.roundtrip() != .SUCCESS) return error.RoundtripFailed;
    if (self.seat == null or self.ctl == null) return error.MissingGlobals;

    std.log.info("successfully initialized wayland connection", .{});

    return self;
}

pub fn deinit(self: Connection) void {
    self.seat.?.destroy();
    self.ctl.?.destroy();
    self.dpy.disconnect();
}

pub fn runCommand(self: Connection, args: []const [:0]const u8) !void {
    std.log.debug("running command: {f}", .{common.fmt.command(args)});
    for (args) |arg| self.ctl.?.addArgument(arg.ptr);

    var success: ?bool = null;
    const cb = try self.ctl.?.runCommand(self.seat.?);
    cb.setListener(*?bool, cmdCallbackListener, &success);

    while (success == null) {
        if (self.dpy.dispatch() != .SUCCESS) return error.RoundtripFailed;
    }

    if (!success.?) return error.CommandFailed;
}

fn cmdCallbackListener(
    _: *zriver.CommandCallbackV1,
    ev: zriver.CommandCallbackV1.Event,
    success: *?bool,
) void {
    switch (ev) {
        .success => |suc| {
            success.* = true;
            const output = std.mem.span(suc.output);

            if (output.len != 0)
                std.log.info("cmd output: {s}", .{output});
        },
        .failure => |fail| {
            success.* = false;
            std.log.err("cmd fail: {s}", .{fail.failure_message});
        },
    }
}

fn registryListener(reg: *wl.Registry, ev: wl.Registry.Event, self: *Connection) void {
    switch (ev) {
        .global => |glob| {
            if (std.mem.orderZ(u8, glob.interface, wl.Seat.interface.name) == .eq) {
                self.seat = reg.bind(
                    glob.name,
                    wl.Seat,
                    wl.Seat.generated_version,
                ) catch @panic("OOM");
            } else if (std.mem.orderZ(u8, glob.interface, zriver.ControlV1.interface.name) == .eq) {
                self.ctl = reg.bind(
                    glob.name,
                    zriver.ControlV1,
                    zriver.ControlV1.generated_version,
                ) catch @panic("OOM");
            }
        },
        .global_remove => {},
    }
}
