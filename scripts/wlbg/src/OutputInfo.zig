const std = @import("std");
const wayland = @import("wayland");

const wl = wayland.client.wl;
const xdg = wayland.client.xdg;

x: i32 = 0,
y: i32 = 0,
width: i32 = 0,
height: i32 = 0,
