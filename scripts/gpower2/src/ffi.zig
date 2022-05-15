// partially yoinked from https://github.com/Swoogan/ziggtk
pub const c = @cImport({
    @cInclude("gtk/gtk.h");
});

/// Could not get `g_signal_connect` to work. Zig says "use of undeclared identifier". Reimplemented here
pub fn connectSignal(
    instance: c.gpointer,
    detailed_signal: [*c]const c.gchar,
    c_handler: c.GCallback,
    data: c.gpointer,
) void {
    var zero: u32 = 0;
    const flags: *c.GConnectFlags = @ptrCast(*c.GConnectFlags, &zero);
    _ = c.g_signal_connect_data(instance, detailed_signal, c_handler, data, null, flags.*);
}
