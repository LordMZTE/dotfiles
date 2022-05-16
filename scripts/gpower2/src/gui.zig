const std = @import("std");

const Action = @import("action.zig").Action;
const c = ffi.c;
const ffi = @import("ffi.zig");
const u = @import("util.zig");

pub const GuiState = struct {
    child: ?std.ChildProcess = null,
    alloc: std.mem.Allocator,
    /// Allocator used to allocate userdata that will be cleared at the
    /// end of the application lifespan
    user_data_arena: std.mem.Allocator,
};

pub fn activate(app: *c.GtkApplication, state: *GuiState) callconv(.C) void {
    const win = c.gtk_application_window_new(app);
    c.gtk_window_set_title(u.c(*c.GtkWindow, win), "gpower2");
    c.gtk_window_set_modal(u.c(*c.GtkWindow, win), 1);
    c.gtk_window_set_resizable(u.c(*c.GtkWindow, win), 0);
    c.gtk_window_set_icon_name(u.c(*c.GtkWindow, win), "system-shutdown");

    const eck = c.gtk_event_controller_key_new();
    c.gtk_widget_add_controller(win, eck);
    ffi.connectSignal(
        eck,
        "key-pressed",
        u.c(c.GCallback, handleKeypress),
        u.c(*c.GtkWindow, win),
    );

    const content = c.gtk_box_new(c.GTK_ORIENTATION_HORIZONTAL, 20);
    c.gtk_window_set_child(u.c(*c.GtkWindow, win), content);
    inline for (.{ .top, .bottom, .start, .end }) |fun| {
        @field(c, "gtk_widget_set_margin_" ++ @tagName(fun))(content, 20);
    }

    inline for (.{
        Action.Shutdown,
        Action.Reboot,
        Action.Suspend,
        Action.Hibernate,
    }) |action| {
        c.gtk_box_append(
            u.c(*c.GtkBox, content),
            powerButton(state, u.c(*c.GtkWindow, win), action),
        );
    }

    c.gtk_widget_show(win);
}

const ButtonHandlerData = struct {
    state: *GuiState,
    action: Action,
    win: *c.GtkWindow,
};

fn powerButton(
    state: *GuiState,
    win: *c.GtkWindow,
    action: Action,
) *c.GtkWidget {
    const text = @tagName(action);
    const icon = switch (action) {
        Action.Shutdown => "system-shutdown",
        Action.Reboot => "system-reboot",
        Action.Suspend => "system-suspend",
        Action.Hibernate => "system-hibernate",
    };

    var udata = state.user_data_arena.create(ButtonHandlerData) catch @panic("Failed to allocate button handler data!!");
    udata.* = ButtonHandlerData{
        .state = state,
        .win = win,
        .action = action,
    };

    const container = c.gtk_box_new(c.GTK_ORIENTATION_VERTICAL, 2);

    const button = c.gtk_button_new();
    c.gtk_box_append(u.c(*c.GtkBox, container), button);

    ffi.connectSignal(button, "clicked", u.c(c.GCallback, handleClick), udata);

    const image = c.gtk_image_new_from_icon_name(icon);
    c.gtk_button_set_child(u.c(*c.GtkButton, button), image);

    c.gtk_image_set_pixel_size(u.c(*c.GtkImage, image), 60);

    const label = c.gtk_label_new(text);
    c.gtk_box_append(u.c(*c.GtkBox, container), label);

    return container;
}

fn handleClick(
    btn: *c.GtkButton,
    udata: *ButtonHandlerData,
) void {
    _ = btn;
    _ = udata;

    udata.action.execute(&udata.state.child, udata.state.alloc) catch |e| {
        // TODO: error dialog
        std.log.err("Error spawning child: {}", .{e});
    };

    c.gtk_window_close(udata.win);
}

fn handleKeypress(
    eck: *c.GtkEventControllerKey,
    keyval: c.guint,
    keycode: c.guint,
    state: c.GdkModifierType,
    win: *c.GtkWindow,
) c.gboolean {
    _ = eck;
    _ = keycode;
    _ = state;

    if (keyval == c.GDK_KEY_Escape) {
        c.gtk_window_close(win);
        return 1;
    } else {
        return 0;
    }
}
