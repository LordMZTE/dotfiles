//! Utilities regarding the system daemon (systemd)

const std = @import("std");

pub const SystemDaemon = enum {
    none,
    systemd,
};

pub fn getCurrentSystemDaemon() !SystemDaemon {
    const cache = struct {
        var daemon: ?SystemDaemon = null;
    };

    if (cache.daemon) |d|
        return d;

    const systemd_stat: ?std.fs.File.Stat = std.fs.cwd().statFile("/etc/systemd") catch |e| blk: {
        if (e == error.FileNotFound) {
            break :blk null;
        }

        return e;
    };

    const daemon: SystemDaemon = if (systemd_stat) |_| .systemd else .none;
    cache.daemon = daemon;
    return daemon;
}
