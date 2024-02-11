const std = @import("std");
const nvim = @import("nvim");
const znvim = @import("znvim");
const ffi = @import("../ffi.zig");
const ser = @import("../ser.zig");
const c = ffi.c;

pub fn luaPush(l: *c.lua_State) void {
    ser.luaPushAny(l, .{
        .copyBuf = ffi.luaFunc(lCopyBuf),
    });
}

fn lCopyBuf(l: *c.lua_State) !c_int {
    _ = l;
    // create new buffer
    const newbuf = nvim.buflist_new(null, null, 0, nvim.BLN_LISTED | nvim.BLN_NEW) orelse
        return error.Buffer;

    // create memline
    if (nvim.ml_open(newbuf) == nvim.FAIL)
        return error.Buffer;

    // copy lines
    var lnum: i32 = 1;
    while (lnum < nvim.curbuf.*.b_ml.ml_line_count) : (lnum += 1) {
        const line = nvim.ml_get_buf(nvim.curbuf, lnum) orelse return error.Buffer;
        if (nvim.ml_append_buf(newbuf, lnum - 1, line, 0, false) == nvim.FAIL)
            return error.Buffer;
    }

    const ft_opt = znvim.OptionValue.get("filetype", .local);

    // store previous window layout
    const cursor_pos = nvim.curwin.*.w_cursor;
    const topline = nvim.curwin.*.w_topline;

    // activate buffer
    if (nvim.do_buffer(
        nvim.DOBUF_GOTO,
        nvim.DOBUF_FIRST,
        nvim.FORWARD,
        newbuf.*.handle,
        0,
    ) == nvim.FAIL)
        return error.Buffer;

    // set old window layout
    nvim.curwin.*.w_cursor = cursor_pos;
    nvim.curwin.*.w_topline = topline;

    // set new filetype
    try ft_opt.setLog("filetype", .local);

    // apply autocmds
    _ = nvim.apply_autocmds(nvim.EVENT_BUFREADPOST, @constCast("cpbuf"), null, false, nvim.curbuf);
    _ = nvim.apply_autocmds(nvim.EVENT_BUFWINENTER, @constCast("cpbuf"), null, false, nvim.curbuf);

    // ensure redraw
    nvim.redraw_curbuf_later(nvim.UPD_NOT_VALID);

    return 0;
}
