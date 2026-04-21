const std = @import("std");

/// If we're likely in a Nix shell, return the name of that shell or "?" if it's unknown,
/// null otherwise.
pub fn findNixShellName(env: *const std.process.Environ.Map) ?[]const u8 {
    // "Legacy" nix shell
    if (env.get("IN_NIX_SHELL")) |_| return env.get("name") orelse "?";

    // nix3 shell
    // There is no env var to directly detect this, but the path of packages are prepended to $PATH,
    // so we check if the first entry starts with /nix/store
    if (std.mem.startsWith(
        u8,
        env.get("PATH") orelse return null,
        "/nix/store",
    )) return "NIX3";

    return null;
}
