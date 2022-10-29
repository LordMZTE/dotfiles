const c = @import("ffi.zig").c;

pub fn loadTheme(colors: [*]c.ImVec4) void {
    colors[c.ImGuiCol_WindowBg] = c.ImVec4{ .x = 0.12, .y = 0.0, .z = 0.23, .w = 0.8 };
    colors[c.ImGuiCol_ChildBg] = c.ImVec4{ .x = 0.1, .y = 0.0, .z = 0.2, .w = 0.85 };
    colors[c.ImGuiCol_FrameBg] = c.ImVec4{ .x = 0.45, .y = 0.2, .z = 0.69, .w = 1.0 };
    colors[c.ImGuiCol_Button] = c.ImVec4{ .x = 0.33, .y = 0.14, .z = 0.51, .w = 1.0 };
    colors[c.ImGuiCol_ButtonHovered] = c.ImVec4{ .x = 0.7, .y = 0.49, .z = 0.9, .w = 1.0 };
    colors[c.ImGuiCol_TitleBgActive] = c.ImVec4{ .x = 0.33, .y = 0.14, .z = 0.51, .w = 1.0 };
    colors[c.ImGuiCol_Header] = c.ImVec4{ .x = 0.26, .y = 0.1, .z = 0.43, .w = 1.0 };
    colors[c.ImGuiCol_HeaderHovered] = c.ImVec4{ .x = 0.45, .y = 0.2, .z = 0.69, .w = 1.0 };
}
