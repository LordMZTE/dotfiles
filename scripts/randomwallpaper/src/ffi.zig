pub const c = @cImport({
    @cInclude("stdlib.h");
    @cInclude("X11/Xlib.h");
    @cInclude("X11/extensions/Xinerama.h");
});
