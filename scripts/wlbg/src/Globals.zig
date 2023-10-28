const std = @import("std");
const wayland = @import("wayland");

const wl = wayland.client.wl;
const zxdg = wayland.client.zxdg;
const zwlr = wayland.client.zwlr;

const log = std.log.scoped(.globals);

seat: *wl.Seat,
compositor: *wl.Compositor,
layer_shell: *zwlr.LayerShellV1,
xdg_output_manager: *zxdg.OutputManagerV1,
outputs: std.ArrayList(*wl.Output),

const Globals = @This();

const Collector = col: {
    var fields: []const std.builtin.Type.StructField = &.{};
    for (std.meta.fields(Globals)) |field| {
        const Field = @Type(.{ .Optional = .{ .child = field.type } });
        fields = fields ++ [1]std.builtin.Type.StructField{.{
            .name = field.name,
            .type = Field,
            .default_value = @ptrCast(&@as(Field, null)),
            .is_comptime = false,
            .alignment = @alignOf(Field),
        }};
    }
    break :col @Type(.{ .Struct = .{
        .layout = .Auto,
        .fields = fields,
        .decls = &.{},
        .is_tuple = false,
    } });
};

pub fn collect(dpy: *wl.Display) !Globals {
    const registry = try dpy.getRegistry();
    defer registry.destroy();

    var col = Collector{};

    inline for (std.meta.fields(Globals)) |f| {
        if (comptime isList(f.type)) {
            @field(col, f.name) = f.type.init(std.heap.c_allocator);
        }
    }

    errdefer inline for (std.meta.fields(Globals)) |f| {
        if (comptime isList(f.type)) {
            @field(col, f.name).?.deinit();
        }
    };

    registry.setListener(*Collector, registryListener, &col);

    if (dpy.roundtrip() != .SUCCESS) return error.RoundtipFail;

    // TODO don't use undefined. std.mem.zeroInit complains about non-nullable pointers in struct
    var self: Globals = undefined;
    inline for (std.meta.fields(Globals)) |f| {
        @field(self, f.name) = @field(col, f.name) orelse return error.MissingGlobals;
    }
    return self;
}

fn registryListener(reg: *wl.Registry, ev: wl.Registry.Event, col: *Collector) void {
    switch (ev) {
        .global => |global| {
            inline for (std.meta.fields(Collector)) |f| {
                const BaseType = std.meta.Child(f.type);
                const Interface = std.meta.Child(if (comptime isList(BaseType))
                    std.meta.Child(std.meta.FieldType(BaseType, .items))
                else
                    BaseType);
                if (std.mem.orderZ(u8, global.interface, Interface.getInterface().name) == .eq) {
                    log.info("binding global {s}@{}", .{ Interface.getInterface().name, global.name });

                    const bound = reg.bind(
                        global.name,
                        Interface,
                        Interface.generated_version,
                    ) catch return;

                    if (comptime isList(BaseType)) {
                        @field(col, f.name).?.append(bound) catch @panic("OOM");
                    } else {
                        @field(col, f.name) = bound;
                    }
                    return;
                }
            }
        },
        .global_remove => {},
    }
}

fn isList(comptime T: type) bool {
    return @typeInfo(T) == .Struct and
        @hasDecl(T, "init") and
        @hasDecl(T, "deinit") and
        @hasDecl(T, "append");
}
