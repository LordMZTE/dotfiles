const std = @import("std");
const ffi = @import("ffi.zig");
const c = ffi.c;

const modules = struct {
    const jdtls = @import("modules/jdtls.zig");
};

export fn luaopen_mzte_nv(l_: ?*c.lua_State) c_int {
    const l = l_.?;
    c.lua_newtable(l);
    modules.jdtls.pushModtable(l);
    c.lua_setfield(l, -2, "jdtls");
    return 1;
}
