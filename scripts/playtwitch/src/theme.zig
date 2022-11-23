const std = @import("std");
const c = @import("ffi.zig").c;
const log = std.log.scoped(.theme);

pub fn loadTheme(colors: [*]c.ImVec4) void {
    log.info("loading theme", .{});

    colors[c.ImGuiCol_ButtonHovered] = c.ImVec4{ .x = 0.7, .y = 0.49, .z = 0.9, .w = 1.0 };
    colors[c.ImGuiCol_Button] = c.ImVec4{ .x = 0.33, .y = 0.14, .z = 0.51, .w = 1.0 };
    colors[c.ImGuiCol_ChildBg] = c.ImVec4{ .x = 0.1, .y = 0.0, .z = 0.2, .w = 0.85 };
    colors[c.ImGuiCol_FrameBg] = c.ImVec4{ .x = 0.45, .y = 0.2, .z = 0.69, .w = 1.0 };
    colors[c.ImGuiCol_HeaderHovered] = c.ImVec4{ .x = 0.45, .y = 0.2, .z = 0.69, .w = 1.0 };
    colors[c.ImGuiCol_Header] = c.ImVec4{ .x = 0.26, .y = 0.1, .z = 0.43, .w = 1.0 };
    colors[c.ImGuiCol_TableHeaderBg] = c.ImVec4{ .x = 0.45, .y = 0.2, .z = 0.69, .w = 0.8 };
    colors[c.ImGuiCol_TitleBgActive] = c.ImVec4{ .x = 0.33, .y = 0.14, .z = 0.51, .w = 1.0 };
    colors[c.ImGuiCol_WindowBg] = c.ImVec4{ .x = 0.12, .y = 0.0, .z = 0.23, .w = 0.8 };
}

pub fn loadFont() !?*c.ImFont {
    log.info("loading fonts", .{});

    const fonts = [_][:0]const u8{
        "/usr/share/fonts/TTF/Iosevka Nerd Font Complete.ttf",
        "/usr/share/fonts/noto/NotoSans-Regular.ttf",
    };

    for (fonts) |font| {
        const found = if (std.fs.accessAbsolute(font, .{})) |_|
            true
        else |e| if (e == error.FileNotFound)
            true
        else
            return e;

        if (found) {
            log.info("using font {s}", .{font});
            return c.ImFontAtlas_AddFontFromFileTTF(
                c.igGetIO().*.Fonts,
                font.ptr,
                16,
                null,
                null,
            );
        }
    }
    return null;
}
