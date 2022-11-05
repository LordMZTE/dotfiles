pub const c = @cImport({
    @cInclude("curl/curl.h");

    @cInclude("GL/glew.h");
    @cInclude("GLFW/glfw3.h");

    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", "");
    @cInclude("cimgui.h");

    @cDefine("CIMGUI_USE_GLFW", "");
    @cDefine("CIMGUI_USE_OPENGL3", "");
    @cInclude("cimgui_impl.h");
});
