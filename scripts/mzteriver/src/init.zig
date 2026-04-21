const std = @import("std");
const cgopts = @import("cgopts");
const common = @import("common");

fn initCommand(comptime argv: []const [:0]const u8) []const [:0]const u8 {
    return &[_][:0]const u8{
        "systemd-cat",
        "--level-prefix=false",
        "--identifier=" ++ argv[0],
        "--",
    } ++ argv;
}

pub fn init(
    alloc: std.mem.Allocator,
    io: std.Io,
    home: []const u8,
) !std.Io.Future(StartupCommandsError!void) {
    // tell confgenfs we're now using river
    confgenfs: {
        const cgfs_eval_path = try std.fs.path.join(
            alloc,
            &.{ home, "confgenfs", "_cgfs", "eval" },
        );
        defer alloc.free(cgfs_eval_path);

        const evalf = std.Io.Dir.cwd().openFile(io, cgfs_eval_path, .{ .mode = .write_only }) catch {
            std.log.warn("unable to open confgenfs eval file", .{});
            break :confgenfs;
        };
        defer evalf.close(io);

        var writer = evalf.writerStreaming(io, &.{});
        try writer.interface.writeAll(
            \\cg.opt.setCurrentWaylandCompositor "river"
        );
    }

    std.log.info("spawning processes", .{});

    // spawn initialization processes
    var child_group: std.Io.Group = .init;
    defer child_group.cancel(io);

    for ([_][]const []const u8{
        &.{
            "dbus-update-activation-environment",
            "DISPLAY",
            "XAUTHORITY",
            "WAYLAND_DISPLAY",
            "XDG_CURRENT_DESKTOP",
        },
        &.{
            "systemctl",
            "--user",
            "import-environment",
            "DISPLAY",
            "XAUTHORITY",
            "WAYLAND_DISPLAY",
            "XDG_CURRENT_DESKTOP",
        },
    }) |argv| {
        const runChild = struct {
            fn runChild(io_: std.Io, argv_: []const []const u8) !void {
                var child = std.process.spawn(io_, .{ .argv = argv_ }) catch |e| switch (e) {
                    error.Canceled => return error.Canceled,
                    else => {
                        std.log.warn(
                            "couldn't spawn init process {f}: {}",
                            .{ common.fmt.command(argv_), e },
                        );
                        return;
                    },
                };
                _ = child.wait(io_) catch |e| switch (e) {
                    error.Canceled => return error.Canceled,
                    else => {
                        std.log.warn(
                            "couldn't wait for init process {f}: {}",
                            .{ common.fmt.command(argv_), e },
                        );
                        return;
                    },
                };
            }
        }.runChild;
        child_group.async(io, runChild, .{ io, argv });
    }

    const future = try io.concurrent(spawnStartupCommands, .{ alloc, io });
    try child_group.await(io);
    return future;
}

pub const StartupCommandsError = std.mem.Allocator.Error || std.process.SpawnError ||
    std.process.Child.WaitError;

fn spawnStartupCommands(alloc: std.mem.Allocator, io: std.Io) StartupCommandsError!void {
    var children: std.ArrayList(std.process.Child) = try .initCapacity(
        alloc,
        cgopts.startup_commands.len,
    );
    defer {
        for (children.items) |*child| {
            child.kill(io);
        }
        children.deinit(alloc);
    }

    inline for (cgopts.startup_commands) |argv| {
        const child = try std.process.spawn(io, .{ .argv = initCommand(&argv) });
        children.appendAssumeCapacity(child);
    }

    for (children.items) |*child| {
        _ = try child.wait(io);
    }
}
