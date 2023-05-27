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

    // close in case of error
    errdefer _ = nvim.close_buffer(null, newbuf, 0, false, false);

    // create memline
    if (nvim.ml_open(newbuf) == nvim.FAIL)
        return error.Buffer;

    // copy lines
    var lnum: i32 = 1;
    while (lnum < nvim.curbuf.*.b_ml.ml_line_count) : (lnum += 1) {
        const line = nvim.ml_get_buf(nvim.curbuf, lnum, false) orelse return error.Buffer;
        if (nvim.ml_append_buf(newbuf, lnum - 1, line, 0, false) == nvim.FAIL)
            return error.Buffer;
    }

    // get previous filetype
    var ft_numval: i64 = 0;
    var ft_stringval: ?[*:0]u8 = null;
    if (nvim.get_option_value_strict(
        @constCast("filetype"),
        &ft_numval,
        &ft_stringval,
        nvim.SREQ_BUF,
        nvim.curbuf,
    ) == nvim.FAIL)
        return error.Buffer;

    // activate buffer
    if (nvim.do_buffer(
        nvim.DOBUF_GOTO,
        nvim.DOBUF_FIRST,
        nvim.FORWARD,
        newbuf.*.handle,
        0,
    ) == nvim.FAIL)
        return error.Buffer;

    // set new filetype
    if (nvim.set_option_value("filetype", 0, ft_stringval, nvim.OPT_LOCAL)) |_|
        return error.Buffer;

    // apply autocmds
    _ = nvim.apply_autocmds(nvim.EVENT_BUFREADPOST, @constCast("cpbuf"), null, false, nvim.curbuf);
    _ = nvim.apply_autocmds(nvim.EVENT_BUFWINENTER, @constCast("cpbuf"), null, false, nvim.curbuf);


    // ensure redraw
    nvim.redraw_curbuf_later(nvim.UPD_NOT_VALID);

    return 0;
}
