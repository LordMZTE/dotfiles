const std = @import("std");
const lib = @import("lib");
const wb = lib.wb;
const c = lib.c;

comptime {
    lib.wb.defineStandardExterns();
}

// x, y tuples in range of 0-1
const sep_vertices = [_][2]f64{
    .{ 0.0, 0.0 },
    .{ 0.244, 0.244 },
    .{ 0.064, 0.5 },
    .{ 0.5, 0.5 },
    .{ 0.340, 0.732 },
    .{ 0.732, 0.732 },
    .{ 1.0, 1.0 },
};

const Side = enum { left, right };

const Instance = struct {
    draw_area: *c.GtkWidget,
    side: Side,
    left_neighbor: ?*c.GtkWidget,
    right_neighbor: ?*c.GtkWidget,
};

export fn wbcffi_init(
    init_info: *const wb.InitInfo,
    config_entries: [*]const wb.ConfigEntry,
    config_entries_len: usize,
) callconv(.c) ?*Instance {
    return tryInit(init_info, config_entries[0..config_entries_len]) catch |err| {
        std.log.err("Couldn't init: {t}", .{err});
        return null;
    };
}

fn tryInit(init_info: *const wb.InitInfo, config: []const wb.ConfigEntry) !*Instance {
    const instance = try std.heap.c_allocator.create(Instance);
    errdefer std.heap.c_allocator.destroy(instance);

    const root = init_info.getRootWidget();

    const draw_area = c.gtk_drawing_area_new();
    c.gtk_widget_set_vexpand(draw_area, 1);
    _ = c.g_signal_connect_data(
        draw_area,
        "size-allocate",
        @ptrCast(&drawAreaSizeAllocateCb),
        instance,
        null,
        0,
    );
    _ = c.g_signal_connect_data(
        draw_area,
        "draw",
        @ptrCast(&drawAreaDrawCb),
        instance,
        null,
        0,
    );

    c.gtk_container_add(root, draw_area);

    var side: Side = undefined;

    for (config) |conf| {
        if (std.mem.orderZ(u8, conf.key, "side") == .eq) {
            const parsed = try std.json.parseFromSlice(
                Side,
                std.heap.c_allocator,
                std.mem.span(conf.value),
                .{},
            );
            defer parsed.deinit();

            side = parsed.value;
            break;
        }
    } else {
        std.log.err("missing 'side' config value", .{});
        return error.Explained;
    }

    instance.* = .{
        .draw_area = draw_area,
        .side = side,
        .left_neighbor = null,
        .right_neighbor = null,
    };

    _ = c.g_signal_connect_data(root, "show", @ptrCast(&showCb), instance, null, 0);

    return instance;
}

export fn wbcffi_deinit(instance: *Instance) void {
    if (instance.left_neighbor) |l| c.g_object_unref(l);
    if (instance.right_neighbor) |r| c.g_object_unref(r);
    std.heap.c_allocator.destroy(instance);
}

fn showCb(widget: *c.GtkWidget, instance: *Instance) callconv(.c) void {
    const bar = c.gtk_widget_get_parent(widget);
    const children = c.gtk_container_get_children(@ptrCast(bar));
    defer c.g_list_free(children);

    var before: ?*c.GtkWidget = null;
    var after: ?*c.GtkWidget = null;

    var cur_node = children;
    while (cur_node) |ch| {
        if (ch.*.next != null and @intFromPtr(ch.*.next.*.data) == @intFromPtr(widget)) {
            before = @ptrCast(@alignCast(ch.*.data));
        } else if (ch.*.prev != null and @intFromPtr(ch.*.prev.*.data) == @intFromPtr(widget)) {
            after = @ptrCast(@alignCast(ch.*.data));
        }
        cur_node = ch.*.next;
    }

    for ([_]*?*c.GtkWidget{ &before, &after }) |maybe_neighbor| {
        if (maybe_neighbor.*) |neighbor| {
            // The immediate neighbor widget is just a container, grab its child which has a background
            // we can draw onto ourselves.

            const ChildGrabber = struct {
                fn foreachCb(child: *c.GtkWidget, out_ptr: *?*c.GtkWidget) callconv(.c) void {
                    if (out_ptr.* == null) {
                        out_ptr.* = child;
                    }
                }
            };

            maybe_neighbor.* = null;
            c.gtk_container_foreach(
                @ptrCast(neighbor),
                @ptrCast(&ChildGrabber.foreachCb),
                @ptrCast(maybe_neighbor),
            );

            if (maybe_neighbor.*) |child| {
                _ = c.g_signal_connect_data(
                    child,
                    "draw",
                    @ptrCast(&neighborDrawCb),
                    instance,
                    null,
                    0,
                );
            }
        }
    }

    if (instance.left_neighbor) |l| c.g_object_unref(l);
    if (before) |b| _ = c.g_object_ref(b);
    instance.left_neighbor = before;

    if (instance.right_neighbor) |r| c.g_object_unref(r);
    if (after) |a| _ = c.g_object_ref(a);
    instance.right_neighbor = after;
}

fn neighborDrawCb(neighbor: *c.GtkWidget, cr: *c.cairo_t, instance: *Instance) callconv(.c) c_int {
    _ = neighbor;
    _ = cr;

    // When a neighbor is redrawn, we need to update our color.
    c.gtk_widget_queue_draw(instance.draw_area);
    return 0;
}

// Make the draw area request width such that it becomes a square
fn drawAreaSizeAllocateCb(
    draw_area: *c.GtkWidget,
    allocation: *c.GtkAllocation,
    instance: *Instance,
) callconv(.c) void {
    _ = instance;

    const cur_width = allocation.width;
    const want_width = allocation.height;

    if (cur_width != want_width) {
        c.gtk_widget_set_size_request(draw_area, want_width, allocation.height);
    }
}

fn drawAreaDrawCb(
    draw_area: *c.GtkWidget,
    cr: *c.cairo_t,
    instance: *Instance,
) callconv(.c) c_int {
    const width: f64 = @floatFromInt(c.gtk_widget_get_allocated_width(draw_area));
    const height: f64 = @floatFromInt(c.gtk_widget_get_allocated_height(draw_area));

    // Left side
    if (instance.left_neighbor) |neighbor| {
        c.cairo_save(cr);
        defer c.cairo_restore(cr);

        clipToCairo(cr, width, height, instance.side, true);
        c.cairo_clip(cr);

        const style_ctx = c.gtk_widget_get_style_context(neighbor);
        c.gtk_render_background(style_ctx, cr, 0, 0, width, height);
    }

    // Right side
    if (instance.right_neighbor) |neighbor| {
        c.cairo_save(cr);
        defer c.cairo_restore(cr);

        clipToCairo(cr, width, height, instance.side, false);
        c.cairo_clip(cr);

        const style_ctx = c.gtk_widget_get_style_context(neighbor);
        c.gtk_render_background(style_ctx, cr, 0, 0, width, height);
    }

    return 0;
}

fn clipToCairo(cr: *c.cairo_t, width: f64, height: f64, side: Side, invert: bool) void {
    if (invert) {
        c.cairo_move_to(cr, 0, 0);
    } else {
        c.cairo_move_to(cr, width, 0);
    }

    for (sep_vertices) |vert| {
        switch (side) {
            .left => c.cairo_line_to(cr, (1.0 - vert[0]) * width, vert[1] * height),
            .right => c.cairo_line_to(cr, vert[0] * width, vert[1] * height),
        }
    }

    if (invert) {
        c.cairo_line_to(cr, 0, height);
    } else {
        c.cairo_line_to(cr, width, height);
    }

    c.cairo_close_path(cr);
}
