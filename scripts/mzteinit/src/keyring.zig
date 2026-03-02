const std = @import("std");

/// Links the user keyring into the session keyring.  This is required for the user keyring to be
/// usable and is sometimes done by PAM on login already, but, on NixOS, it's not the default.
pub fn linkUserKeyring() !void {
    std.log.info("linking user keyring", .{});
    const rc = std.os.linux.syscall3(
        std.os.linux.SYS.keyctl,
        8, // KEYCTL_LINK
        @bitCast(@as(isize, -4)), // KEY_SPEC_USER_KEYRING
        @bitCast(@as(isize, -3)), // KEY_SPEC_SESSION_KEYRING
    );

    return switch (std.posix.E.init(rc)) {
        .SUCCESS => {},
        .NOKEY, .KEYEXPIRED, .KEYREVOKED, .ACCES => error.KeyError,
        else => |err| std.posix.unexpectedErrno(err),
    };
}
