const c = @import("c.zig").c;

pub fn defineStandardExterns() void {
    _ = struct {
        export const wbcffi_version: usize = 2;
    };
}

// The following definitions are adapted from:
// https://github.com/Alexays/Waybar/blob/master/resources/custom_modules/cffi_example/waybar_cffi_module.h

// wbcffi_module
/// Private Waybar CFFI module
pub const Module = opaque {};

// wbcffi_init_info
/// Waybar module information
pub const InitInfo = extern struct {
    /// Waybar CFFI object pointer
    obj: *Module,

    /// Waybar version string
    waybar_version: [*:0]const u8,

    /// Returns the waybar widget allocated for this module
    get_root_widget: *const fn (
        // TODO: remove this comment when it's no longer needed for `zig fmt` to not destroy this
        // code: https://github.com/ziglang/zig/issues/14654
        /// Waybar CFFI object pointer
        obj: *Module,
    ) callconv(.c) *c.GtkContainer,

    /// Queues a request for calling wbcffi_update() on the next GTK main event loop iteration
    queue_update: *const fn (
        // TODO: remove this comment when it's no longer needed for `zig fmt` to not destroy this
        // code: https://github.com/ziglang/zig/issues/14654
        /// Waybar CFFI object pointer
        obj: *Module,
    ) callconv(.c) void,

    pub fn getRootWidget(self: InitInfo) *c.GtkContainer {
        return self.get_root_widget(self.obj);
    }

    pub fn queueUpdate(self: InitInfo) void {
        self.queue_update(self.obj);
    }
};

// wbcffi_config_entry
/// Config key-value pair
pub const ConfigEntry = extern struct {
    /// Entry Key
    key: [*:0]const u8,

    /// Entry value
    ///
    /// In ABI version 1, this may be either a bare string if the value is a
    /// string, or the JSON representation of any other JSON object as a string.
    ///
    /// From ABI version 2 onwards, this is always the JSON representation of the
    /// value as a string.
    value: [*:0]const u8,
};
