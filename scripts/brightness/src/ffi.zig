const c = @import("c");

pub fn checkDDCAError(errno: c.DDCA_Status) !void {
    if (errno != 0) return error.DDCAError;
}
