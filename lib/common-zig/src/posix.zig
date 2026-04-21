//! A module containing useful POSIX routines that Zig nonsensically removed from std in 0.16.
const std = @import("std");

const native_os = @import("builtin").os.tag;

pub const EPoll = struct {
    handle: std.posix.fd_t,

    pub fn init() !EPoll {
        const epfd = std.posix.system.epoll_create1(0);
        switch (std.posix.errno(epfd)) {
            .SUCCESS => {},
            .MFILE => return error.ProcessFdQuoteExceeded,
            .NFILE => return error.SystemFdQuoteExceeded,
            .NOMEM => return error.OutOfMemory,
            else => |errno| return std.posix.unexpectedErrno(errno),
        }

        return .{ .handle = epfd };
    }

    pub fn deinit(self: EPoll) void {
        _ = std.posix.system.close(self.handle);
    }

    pub fn addFd(self: EPoll, fd: std.posix.fd_t, events: u32) !void {
        var ev: std.os.linux.epoll_event = .{
            .events = events,
            .data = .{ .fd = fd },
        };

        const rc = std.os.linux.epoll_ctl(self.handle, std.os.linux.EPOLL.CTL_ADD, fd, &ev);
        switch (std.posix.errno(rc)) {
            .SUCCESS => {},
            .EXIST => return error.FileDescriptorAlreadyRegistered,
            .LOOP => return error.Loop,
            .NOSPC => return error.ProcessFdQuoteExceeded,
            .PERM => return error.PermissionDenied,
            else => |errno| return std.posix.unexpectedErrno(errno),
        }
    }

    pub fn wait(
        self: EPoll,
        buf: []std.os.linux.epoll_event,
        timeout: i32,
    ) ![]std.os.linux.epoll_event {
        const rc = std.os.linux.epoll_wait(self.handle, buf.ptr, @intCast(buf.len), timeout);
        switch (std.posix.errno(rc)) {
            .SUCCESS => {},
            .INTR => return error.Timeout,
            else => |errno| return std.posix.unexpectedErrno(errno),
        }
        return buf[0..rc];
    }
};

pub const TimerFd = struct {
    handle: std.posix.fd_t,

    pub fn init(clock: std.posix.system.timerfd_clockid_t, flags: c_int) !TimerFd {
        const rc = std.posix.system.timerfd_create(clock, flags);
        switch (std.posix.errno(rc)) {
            .SUCCESS => {},
            .MFILE => return error.ProcessFdQuoteExceeded,
            .NFILE => return error.SystemFdQuoteExceeded,
            .NOMEM => return error.OutOfMemory,
            .PERM => return error.PermissionDenied,
            else => |errno| return std.posix.unexpectedErrno(errno),
        }
        return .{ .handle = rc };
    }

    pub fn deinit(self: TimerFd) void {
        _ = std.posix.system.close(self.handle);
    }

    pub fn setTime(self: TimerFd, value: std.posix.timespec, interval: std.posix.timespec) !void {
        const rc = std.posix.system.timerfd_settime(self.handle, 0, &.{
            .it_value = value,
            .it_interval = interval,
        }, null);

        switch (std.posix.errno(rc)) {
            .SUCCESS => {},
            else => |errno| return std.posix.unexpectedErrno(errno),
        }
    }
};

pub fn socket(domain: u32, socket_type: u32, protocol: u32) !std.posix.fd_t {
    const rc = std.posix.system.socket(domain, socket_type, protocol);
    switch (std.posix.errno(rc)) {
        .SUCCESS => {},
        .AFNOSUPPORT => return error.AddressFamilyUnsupported,
        .MFILE => return error.ProcessFdQuoteExceeded,
        .NFILE => return error.SystemFdQuoteExceeded,
        .NOBUFS, .NOMEM => return error.OutOfMemory,
        .PROTONOSUPPORT => return error.ProtocolUnsupportedByAddressFamily,
        else => |errno| return std.posix.unexpectedErrno(errno),
    }
    return rc;
}

pub fn connect(sockfd: std.posix.fd_t, sockaddr: *const std.posix.sockaddr, addrlen: u32) !void {
    const rc = std.posix.system.connect(sockfd, sockaddr, addrlen);
    switch (std.posix.errno(rc)) {
        .SUCCESS => {},
        .ADDRNOTAVAIL => return error.AddressNotAvailable,
        .AFNOSUPPORT => return error.AddressFamilyUnsupported,
        .ALREADY => return error.ConnectionPending,
        .CONNREFUSED => return error.ConnectionRefused,
        .INTR => return error.Interrupted,
        .ISCONN => return error.AlreadyConnected,
        .NETUNREACH => return error.NetworkUnreachable,
        .PROTOTYPE => return error.SocketModeUnsupported,
        .IO => return error.InputOutput,
        .LOOP => return error.Loop,
        .NOENT => return error.NoSuchFileOrDirectory,
        .ACCES => return error.AccessDenied,
        .ADDRINUSE => return error.AddressInUse,
        .CONNRESET => return error.ConnectionReset,
        .HOSTUNREACH => return error.HostUnreachable,
        .NETDOWN => return error.NetworkDown,
        .NOBUFS => return error.OutOfMemory,
        else => |errno| return std.posix.unexpectedErrno(errno),
    }
}

pub const UnixAddress = extern union {
    any: std.posix.sockaddr,
    un: std.posix.sockaddr.un,
};

/// This function is from Zig std, but private so it had to be copied here.
pub fn addressUnixToPosix(a: *const std.Io.net.UnixAddress, storage: *UnixAddress) std.posix.socklen_t {
    storage.un.family = std.posix.AF.UNIX;
    var path_len = switch (native_os) {
        .windows => @min(a.path.len, storage.un.path.len),
        else => a.path.len,
    };
    // With the AFD API, `sockaddr.un` is purely informational, so
    // use a suffix which is usually the most relevant part of a path.
    @memcpy(storage.un.path[0..path_len], a.path[a.path.len - path_len ..]);
    if (storage.un.path.len - path_len > 0) {
        @branchHint(.likely);
        storage.un.path[path_len] = 0;
        path_len += 1;
    }
    switch (native_os) {
        .windows => {
            if (storage.un.path[0] == 0) @memset(storage.un.path[path_len..], 0);
            return @sizeOf(std.posix.sockaddr.un);
        },
        else => return @intCast(@offsetOf(std.posix.sockaddr.un, "path") + path_len),
    }
}

pub fn sendmsg(fd: std.posix.fd_t, msg: *const std.posix.msghdr_const, flags: u32) !usize {
    const rc = std.posix.system.sendmsg(fd, msg, flags);

    switch (std.posix.errno(rc)) {
        .SUCCESS => {},
        .AGAIN => return error.WouldBlock,
        .CONNRESET => return error.ConnectionReset,
        .INTR => return error.Interrupted,
        .MSGSIZE => return error.BufferOverflow,
        .NOTCONN => return error.NotConnected,
        .PIPE => return error.BrokenPipe,
        else => |errno| return std.posix.unexpectedErrno(errno),
    }

    return @intCast(rc);
}
