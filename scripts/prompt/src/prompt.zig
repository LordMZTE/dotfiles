const std = @import("std");
const at = @import("ansi-term");
const known_folders = @import("known-folders");
const ffi = @import("ffi.zig");
const checkGitError = ffi.checkGitError;
const c = ffi.c;
const ViMode = @import("vi_mode.zig").ViMode;
const Shell = @import("shell.zig").Shell;

const Style = at.style.Style;
const Color = at.style.Color;

const symbols = struct {
    const left_separator = "";
    const right_separator = "";
    const top_left = "";
    const bottom_left = "";
    const path_separator = "❯";
    const top_end = "";
    const staged = "";
    const unstaged = "";
    const home = "";
    const root = "";
    const watch = "";
    const jobs = "";
    const nix = "󱄅";
    const bash = "";
};

pub const Options = struct {
    status: i32,
    mode: ViMode,
    duration: u32,
    jobs: u32,
    nix_name: ?[]const u8,
    shell: Shell,
};

pub fn render(writer: anytype, options: Options) !void {
    var renderer = Renderer(@TypeOf(writer)){
        .last_style = null,
        .writer = writer,
        .options = options,
    };
    try renderer.render();
}

fn Renderer(comptime Writer: type) type {
    return struct {
        last_style: ?Style,
        writer: Writer,
        options: Options,

        const Self = @This();

        pub fn render(self: *Self) !void {
            const left_color: Color = if (self.options.status == 0) .Green else .Red;

            try self.setStyle(.{ .foreground = left_color });
            try self.writer.writeAll(symbols.top_left);
            try self.setStyle(.{ .background = left_color });
            try self.renderShell();
            try self.renderDuration();
            try self.renderJobs();
            try self.renderCwd();
            try self.renderNix();
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

            if (self.options.mode != ._none) {
                const mode_color = self.options.mode.getColor();

                try self.setStyle(.{
                    .foreground = left_color,
                    .background = mode_color,
                    .font_style = .{ .bold = true },
                });
                try self.writer.writeAll(symbols.right_separator ++ " ");
                try self.setStyle(.{
                    .foreground = .Black,
                    .background = mode_color,
                    .font_style = .{ .bold = true },
                });
                try self.writer.writeByte(self.options.mode.getChar());
                try self.writer.writeByte(' ');
                try self.setStyle(.{ .foreground = mode_color });
            } else {
                try self.writer.writeByte(' ');
                try self.setStyle(.{ .foreground = left_color });
            }

            try self.writer.writeAll(symbols.right_separator ++ " ");
            try self.setStyle(.{});
        }

        fn renderShell(self: *Self) !void {
            switch (self.options.shell) {
                .fish => {},
                .bash => {
                    const bgcol = Color{ .Grey = 150 };
                    const fgcol = Color.Black;
                    try self.drawLeftSep(bgcol);
                    try self.setStyle(.{ .background = bgcol, .foreground = fgcol });

                    try self.writer.writeAll(" " ++ symbols.bash);
                },
            }
        }

        fn renderDuration(self: *Self) !void {
            if (self.options.duration < 2 * std.time.ms_per_s)
                return;

            try self.drawLeftSep(.Blue);
            try self.setStyle(.{
                .background = .Blue,
                .foreground = .Black,
                .font_style = .{ .bold = true },
            });
            try self.writer.writeAll(" ");
            try self.writer.writeAll(symbols.watch);
            try self.writer.writeAll(" ");

            var total = self.options.duration;

            const hours = total / std.time.ms_per_hour;
            total -= hours * std.time.ms_per_hour;

            const minutes = total / std.time.ms_per_min;
            total -= minutes * std.time.ms_per_min;

            const seconds = total / std.time.ms_per_s;
            total -= seconds * std.time.ms_per_s;

            const millis = total;

            if (hours > 0) {
                try self.writer.print("{}h ", .{hours});
            }

            if (minutes > 0 or hours > 0) {
                try self.writer.print("{}min ", .{minutes});
            }

            if (seconds > 0 or minutes > 0 or hours > 0) {
                try self.writer.print("{}s ", .{seconds});
            }

            if (millis > 0 or seconds > 0 or minutes > 0 or hours > 0) {
                try self.writer.print("{}ms", .{millis});
            }
        }

        fn renderJobs(self: *Self) !void {
            if (self.options.jobs <= 0)
                return;

            try self.drawLeftSep(.Cyan);
            try self.setStyle(.{ .background = .Cyan, .foreground = .Black });

            try self.writer.print(" {s} {}", .{ symbols.jobs, self.options.jobs });
        }

        fn renderCwd(self: *Self) !void {
            var cwd_buf: [512]u8 = undefined;
            const cwd = try std.posix.getcwd(&cwd_buf);

            const home_path = (try known_folders.getPath(std.heap.c_allocator, .home));

            try self.drawLeftSep(.{ .Yellow = {} });
            var written_path = false;
            if (home_path) |home| {
                defer std.heap.c_allocator.free(home);
                if (std.mem.startsWith(u8, cwd, home)) {
                    try self.setStyle(.{
                        .background = .Yellow,
                        .foreground = .Red,
                    });
                    try self.writer.writeAll(" " ++ symbols.home);
                    if (home.len != cwd.len) {
                        try self.renderPathSep();
                        try self.renderPath(cwd[(home.len + 1)..]);
                    }
                    written_path = true;
                }
            }

            // write root-relative path
            if (!written_path) {
                try self.setStyle(.{
                    .background = .Yellow,
                    .foreground = .Red,
                });
                try self.writer.writeAll(" " ++ symbols.root);

                // don't render separators when we're in /
                if (cwd.len > 1) {
                    try self.renderPathSep();
                    try self.renderPath(cwd[1..]);
                }
            }
        }

        fn renderNix(self: *Self) !void {
            if (self.options.nix_name) |name| {
                try self.drawLeftSep(.Blue);
                try self.setStyle(.{ .background = .Blue, .foreground = .Black });

                try self.writer.print(" {s} {s}", .{ symbols.nix, name });
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
                .foreground = .Blue,
            });

            try self.writer.writeAll(" " ++ symbols.path_separator ++ " ");

            try self.setStyle(.{
                .background = self.last_style.?.background,
                .foreground = .Black,
            });
        }

        fn renderGit(self: *Self) !void {
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
                const bg = Color{ .Grey = 200 };
                try self.drawLeftSep(bg);
                try self.setStyle(.{
                    .background = bg,
                    .foreground = .Black,
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
                .foreground = .Black,
                .font_style = .{ .bold = true },
            });
            // using print here because name is a cstring
            try self.writer.print(" {s}", .{name});

            if (counts.staged > 0) {
                try self.drawLeftSep(.Green);
                try self.setStyle(.{
                    .background = .Green,
                    .foreground = .Black,
                });

                try self.writer.print(" {}{s}", .{ counts.staged, symbols.staged });
            }

            if (counts.unstaged > 0) {
                try self.drawLeftSep(.Magenta);
                try self.setStyle(.{
                    .background = .Magenta,
                    .foreground = .Black,
                });

                try self.writer.print(" {}{s}", .{ counts.unstaged, symbols.unstaged });
            }
        }

        fn setStyle(self: *Self, style: Style) !void {
            try at.format.updateStyle(self.writer, style, self.*.last_style);
            self.last_style = style;
        }

        fn drawLeftSep(self: *Self, new_bg: Color) !void {
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

    const counts: *GitStatusCounts = @ptrCast(@alignCast(counts_));

    if (flags & staged_flags > 0)
        counts.staged += 1;

    if (flags & unstaged_flags > 0)
        counts.unstaged += 1;

    return 0;
}

const GitStatusCounts = struct {
    staged: u32 = 0,
    unstaged: u32 = 0,

    pub fn getColor(self: *GitStatusCounts) Color {
        const has_staged = self.staged > 0;
        const has_unstaged = self.unstaged > 0;

        return if (!has_staged and !has_unstaged)
            .Blue
        else if (has_staged and has_unstaged)
            .Magenta
        else if (has_staged)
            .Green
        else
            .{ .Grey = 200 };
    }
};
