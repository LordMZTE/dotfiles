pub const c = @cImport({
    @cInclude("ddcutil_c_api.h");
});

pub fn checkDDCAError(errno: c.DDCA_Status) !void {
    if (errno != 0) return error.DDCAError;
}
