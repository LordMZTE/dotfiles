/// shortcut for ptrCast
pub fn c(comptime T: type, x: anytype) T {
    return @ptrCast(T, x);
}
