const std = @import("std");

/// If we're likely in a Nix shell, return the name of that shell or "?" if it's unknown,
/// null otherwise.
pub fn findNixShellName() ?[]const u8 {
    return if (isInNixShell()) std.posix.getenv("name") orelse "?" else null;
}

fn isInNixShell() bool {
    if (std.posix.getenv("IN_NIX_SHELL")) |_| return true;

    var path_iter = std.mem.splitScalar(
        u8,
        std.posix.getenv("PATH") orelse return false,
        ':',
    );

    while (path_iter.next()) |p|
        if (std.mem.startsWith(u8, p, "/nix/store")) return true;

    return false;
}
