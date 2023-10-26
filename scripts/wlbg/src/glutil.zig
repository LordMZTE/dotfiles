const std = @import("std");
const c = @import("ffi.zig").c;

pub fn createShader(shadertype: c_uint, src: []const u8) !c_uint {
    const id = c.glCreateShader(shadertype);
    c.glShaderSource(
        id,
        1,
        &[_][*]const u8{src.ptr},
        &[_]c_int{@as(c_int, @intCast(src.len))},
    );
    c.glCompileShader(id);

    var success: c_int = 0;
    c.glGetShaderiv(id, c.GL_COMPILE_STATUS, &success);

    if (success == 0) {
        var info_log = std.mem.zeroes([512:0]u8);
        c.glGetShaderInfoLog(id, info_log.len, null, &info_log);
        std.log.err("shader compile error:\n{s}", .{&info_log});
        return error.ShaderCompile;
    }
    return id;
}
