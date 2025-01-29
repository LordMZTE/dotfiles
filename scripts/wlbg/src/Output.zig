const std = @import("std");
const wayland = @import("wayland");
const wl = wayland.client.wl;
const xdg = wayland.client.zxdg;

alloc: std.mem.Allocator,
output: *wl.Output,
id: u32,
width: u31,
height: u31,
name: ?[]const u8,

const Output = @This();

pub fn init(alloc: std.mem.Allocator, wlo: *wl.Output, id: u32) !*Output {
    const self = try alloc.create(Output);

    self.* = .{
        .alloc = alloc,
        .output = wlo,
        .id = id,
        .width = 0,
        .height = 0,
        .name = null,
    };
    wlo.setListener(*Output, listener, self);

    return self;
}

pub fn deinit(self: *Output) void {
    self.output.destroy();
    if (self.name) |n| self.alloc.free(n);
    self.alloc.destroy(self);
}

fn listener(outp: *wl.Output, ev: wl.Output.Event, self: *Output) void {
    _ = outp;
    switch (ev) {
        .name => |nev| {
            std.debug.assert(self.name == null);
            self.name = self.alloc.dupe(u8, std.mem.span(nev.name)) catch @panic("OOM");
        },
        .mode => |modeev| {
            self.width = @intCast(modeev.width);
            self.height = @intCast(modeev.height);
        },
        else => {},
    }
}
