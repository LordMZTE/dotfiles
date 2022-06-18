const std = @import("std");
const at = @import("ansi-term");
const known_folders = @import("known-folders");
const ffi = @import("ffi.zig");
const checkGitError = ffi.checkGitError;
const c = ffi.c;
const FishMode = @import("FishMode.zig");

const symbols = struct {
    const left_separator = "";
    const right_separator = "";
    const top_left = "";
    const bottom_left = "";
    const path_separator = "❯";
    const top_end = "";
    const staged = "";
    const unstaged = "";
    const home = "";
    const root = "";
};

pub fn render(writer: anytype, status: i16, mode: FishMode) !void {
    _ = status;
    _ = mode;

    try (Renderer(@TypeOf(writer)){
        .last_style = null,
        .writer = writer,
        .status = status,
        .mode = mode,
    }).render();
}

fn Renderer(comptime Writer: type) type {
    return struct {
        last_style: ?at.Style,
        writer: Writer,
        status: i16,
        mode: FishMode,

        const Self = @This();

        pub fn render(self: *Self) !void {
            //const alloc = std.heap.c_allocator;

            const left_color = if (self.status == 0)
                at.Color{ .Green = {} }
            else
                at.Color{ .Red = {} };

            try self.setStyle(.{ .foreground = left_color });
            try self.writer.writeAll(symbols.top_left);
            try self.setStyle(.{ .background = left_color });
            try self.renderCwd();
            self.renderGit() catch |err| {
                switch (err) {
                    error.GitError => {}, // git error will be printed
                    else => return err,
                }
            };

            try self.writer.writeAll(" ");
            try self.setStyle(.{ .foreground = self.last_style.?.background });
            try self.writer.writeAll(symbols.top_end ++ "\n");

            try self.setStyle(.{ .foreground = left_color });
            try self.writer.writeAll(symbols.bottom_left);
            try self.setStyle(.{ .foreground = left_color, .background = left_color });
            try self.writer.writeAll(" ");

            const mode_color = self.mode.getColor();

            try self.setStyle(.{
                .foreground = left_color,
                .background = mode_color,
                .font_style = .{ .bold = true },
            });
            try self.writer.writeAll(symbols.right_separator ++ " ");
            try self.setStyle(.{
                .foreground = .{ .Black = {} },
                .background = mode_color,
                .font_style = .{ .bold = true },
            });
            try self.writer.writeAll(self.mode.getText());
            try self.writer.writeAll(" ");
            try self.setStyle(.{ .foreground = mode_color });
            try self.writer.writeAll(symbols.right_separator ++ " ");
            try self.setStyle(.{});
        }

        fn renderCwd(self: *Self) !void {
            const pwd = std.fs.cwd();
            const realpath = try pwd.realpathAlloc(std.heap.c_allocator, ".");
            defer std.heap.c_allocator.free(realpath);

            const home_path = (try known_folders.getPath(std.heap.c_allocator, .home));

            try self.drawLeftSep(.{ .Yellow = {} });
            var written_path = false;
            if (home_path) |home| {
                defer std.heap.c_allocator.free(home);
                if (std.mem.startsWith(u8, realpath, home)) {
                    try self.setStyle(.{
                        .background = .{ .Yellow = {} },
                        .foreground = .{ .Magenta = {} },
                    });
                    try self.writer.writeAll(" " ++ symbols.home);
                    if (home.len != realpath.len) {
                        try self.renderPathSep();
                        try self.renderPath(realpath[(home.len + 1)..]);
                    }
                    written_path = true;
                }
            }

            // write root-relative path
            if (!written_path) {
                try self.setStyle(.{
                    .background = .{ .Yellow = {} },
                    .foreground = .{ .Red = {} },
                });
                try self.writer.writeAll(" " ++ symbols.root);

                // don't render separators when we're in /
                if (realpath.len > 1) {
                    try self.renderPathSep();
                    try self.renderPath(realpath[1..]);
                }
            }
        }

        fn renderPath(self: *Self, path: []const u8) !void {
            for (path) |byte|
                if (byte == '/')
                    try self.renderPathSep()
                else
                    try self.writer.writeByte(byte);
        }

        fn renderPathSep(self: *Self) !void {
            try self.setStyle(.{
                .background = self.last_style.?.background,
                .foreground = .{ .Blue = {} },
            });

            try self.writer.writeAll(" " ++ symbols.path_separator ++ " ");

            try self.setStyle(.{
                .background = self.last_style.?.background,
                .foreground = .{ .Black = {} },
            });
        }

        fn renderGit(self: *Self) !void {
            _ = self;
            try checkGitError(c.git_libgit2_init());
            defer _ = c.git_libgit2_shutdown();

            var path_buf = std.mem.zeroes(c.git_buf);
            defer c.git_buf_dispose(&path_buf);
            if (c.git_repository_discover(&path_buf, ".", 1, null) < 0)
                // no repo found
                return;

            var repo: ?*c.git_repository = null;
            try checkGitError(c.git_repository_open(&repo, path_buf.ptr));
            defer c.git_repository_free(repo);

            var head: ?*c.git_reference = null;
            const head_err = c.git_repository_head(&head, repo);

            // branch with no commits
            if (head_err == c.GIT_EUNBORNBRANCH) {
                const bg = at.Color{ .Grey = 200 };
                try self.drawLeftSep(bg);
                try self.setStyle(.{
                    .background = bg,
                    .foreground = .{ .Black = {} },
                    .font_style = .{ .bold = true },
                });
                try self.writer.writeAll(" <new branch>");

                return;
            }

            defer c.git_reference_free(head);
            const name = c.git_reference_shorthand(head);

            var status_options: c.git_status_options = undefined;
            try checkGitError(c.git_status_options_init(
                &status_options,
                c.GIT_STATUS_OPTIONS_VERSION,
            ));

            status_options.flags =
                c.GIT_STATUS_OPT_INCLUDE_UNTRACKED |
                c.GIT_STATUS_OPT_RECURSE_UNTRACKED_DIRS;

            var status_list: ?*c.git_status_list = null;
            try checkGitError(c.git_status_list_new(
                &status_list,
                repo,
                &status_options,
            ));

            var counts = GitStatusCounts{};
            try checkGitError(c.git_status_foreach_ext(
                repo,
                &status_options,
                gitStatusCb,
                &counts,
            ));

            // now render all that info!
            const ref_bg = counts.getColor();
            try self.drawLeftSep(ref_bg);

            try self.setStyle(.{
                .background = ref_bg,
                .foreground = .{ .Black = {} },
                .font_style = .{ .bold = true },
            });
            // using print here because name is a cstring
            try self.writer.print(" {s}", .{name});

            if (counts.staged > 0) {
                try self.drawLeftSep(.{ .Green = {} });
                try self.setStyle(.{
                    .background = .{ .Green = {} },
                    .foreground = .{ .Black = {} },
                });

                try self.writer.print(" {}{s}", .{ counts.staged, symbols.staged });
            }

            if (counts.unstaged > 0) {
                try self.drawLeftSep(.{ .Magenta = {} });
                try self.setStyle(.{
                    .background = .{ .Magenta = {} },
                    .foreground = .{ .Black = {} },
                });

                try self.writer.print(" {}{s}", .{ counts.unstaged, symbols.unstaged });
            }
        }

        fn setStyle(self: *Self, style: at.Style) !void {
            try at.updateStyle(self.writer, style, self.*.last_style);
            self.last_style = style;
        }

        fn drawLeftSep(self: *Self, new_bg: at.Color) !void {
            try self.writer.writeAll(" ");
            try self.setStyle(.{
                .background = self.last_style.?.background,
                .foreground = new_bg,
            });
            try self.writer.writeAll(symbols.left_separator);
        }
    };
}

fn gitStatusCb(
    _: [*c]const u8,
    flags: c_uint,
    counts_: ?*anyopaque,
) callconv(.C) c_int {
    const staged_flags =
        c.GIT_STATUS_INDEX_NEW |
        c.GIT_STATUS_INDEX_MODIFIED |
        c.GIT_STATUS_INDEX_DELETED |
        c.GIT_STATUS_INDEX_RENAMED |
        c.GIT_STATUS_INDEX_TYPECHANGE;

    const unstaged_flags =
        c.GIT_STATUS_WT_NEW |
        c.GIT_STATUS_WT_MODIFIED |
        c.GIT_STATUS_WT_DELETED |
        c.GIT_STATUS_WT_RENAMED |
        c.GIT_STATUS_WT_TYPECHANGE;

    const counts = @ptrCast(
        *GitStatusCounts,
        @alignCast(@alignOf(GitStatusCounts), counts_),
    );

    if (flags & staged_flags > 0)
        counts.staged += 1;

    if (flags & unstaged_flags > 0)
        counts.unstaged += 1;

    return 0;
}

const GitStatusCounts = struct {
    staged: c_int = 0,
    unstaged: c_int = 0,

    pub fn getColor(self: *GitStatusCounts) at.Color {
        const has_staged = self.staged > 0;
        const has_unstaged = self.unstaged > 0;

        return if (!has_staged and !has_unstaged)
            at.Color{ .Blue = {} }
        else if (has_staged and has_unstaged)
            at.Color{ .Magenta = {} }
        else if (has_staged)
            at.Color{ .Green = {} }
        else
            at.Color{ .Grey = 200 };
    }
};
