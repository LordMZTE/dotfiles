const wl = @import("wayland").client.wl;

active_surface_idx: ?usize,
surface_positions: [][2]c_int,
