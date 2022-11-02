const std = @import("std");
const c = @import("ffi.zig").c;
const State = @import("State.zig");
const log = std.log.scoped(.launch);

pub fn launchChildren(state: *State, channel: []const u8) !void {
    log.info(
        "starting for channel {s} with quality {s} (chatty: {})",
        .{ channel, std.mem.sliceTo(&state.quality_buf, 0), state.chatty },
    );

    // just to be safe...
    state.freeStreamlinkMemfd();

    if (state.chatty and !state.chatty_alive) {
        var chatty_arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
        const channel_d = try std.ascii.allocLowerString(chatty_arena.allocator(), channel);
        const chatty_argv = try chatty_arena.allocator().dupe(
            []const u8,
            &.{ "chatty", "-connect", "-channel", channel_d },
        );
        var chatty_child = std.ChildProcess.init(chatty_argv, std.heap.c_allocator);

        const chatty_thread = try std.Thread.spawn(
            .{},
            chattyThread,
            .{ state, chatty_child, chatty_arena },
        );
        chatty_thread.detach();
    }

    const channel_d = try std.heap.c_allocator.dupe(u8, channel);
    const streamlink_thread = try std.Thread.spawn(
        .{},
        streamlinkThread,
        .{ state, channel_d },
    );
    streamlink_thread.detach();
}

fn streamlinkThread(state: *State, channel: []const u8) !void {
    defer std.heap.c_allocator.free(channel);
    errdefer {
        state.mutex.lock();
        defer state.mutex.unlock();

        c.glfwShowWindow(state.win);
    }

    const memfd = try std.os.memfd_create("streamlink_out", 0);
    errdefer std.os.close(memfd);
    const memfile = std.fs.File{ .handle = memfd };

    var arg_arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arg_arena.deinit();
    const pid = spawn: {
        state.mutex.lock();
        defer state.mutex.unlock();

        var ch_buf: [128]u8 = undefined;
        const lower_channel = std.ascii.lowerString(&ch_buf, channel);

        const url = try std.fmt.allocPrintZ(arg_arena.allocator(), "https://twitch.tv/{s}", .{lower_channel});
        const quality = try std.cstr.addNullByte(arg_arena.allocator(), std.mem.sliceTo(&state.quality_buf, 0));

        const streamlink_argv = try arg_arena.allocator().allocSentinel(
            ?[*:0]const u8,
            3,
            null,
        );

        streamlink_argv[0] = "streamlink";
        streamlink_argv[1] = url;
        streamlink_argv[2] = quality;

        // Doing it the C way because zig's ChildProcess ain't got this
        const pid = try std.os.fork();
        if (pid == 0) {
            try std.os.dup2(memfd, 1);
            try std.os.dup2(memfd, 2);
            return std.os.execvpeZ(streamlink_argv[0].?, streamlink_argv, std.c.environ);
        }

        break :spawn pid;
    };

    var success = std.os.waitpid(pid, 0).status == 0;

    var size = (try memfile.stat()).size;
    if (size == 0) {
        try memfile.writeAll("<no output>");
        size = (try memfile.stat()).size;
    }

    const mem = try std.os.mmap(
        null,
        size,
        std.os.PROT.READ,
        std.os.MAP.PRIVATE,
        memfd,
        0,
    );

    // If the stream ends, this silly program still exits with a non-zero status.
    success = success or std.mem.containsAtLeast(u8, mem, 1, "Stream ended");

    state.mutex.lock();
    defer state.mutex.unlock();

    if (success) {
        std.os.munmap(mem);
        log.info("streamlink exited successfully, closing.", .{});
        c.glfwSetWindowShouldClose(state.win, 1);
    } else {
        state.streamlink_memfd = memfile;
        state.streamlink_out = mem;
        c.glfwShowWindow(state.win);
    }
}

fn chattyThread(state: *State, child: std.ChildProcess, arena: std.heap.ArenaAllocator) !void {
    // no need to get the mutex here, chatty_alive is atomic
    @atomicStore(bool, &state.chatty_alive, true, .Unordered);
    defer @atomicStore(bool, &state.chatty_alive, false, .Unordered);

    var ch = child;
    defer arena.deinit();
    _ = ch.spawnAndWait() catch |e| {
        std.log.err("Spawning Chatty: {!}", .{e});
    };
}
