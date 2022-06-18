const std = @import("std");

pub const c = @cImport({
    @cInclude("git2.h");
});

pub fn checkGitError(errno: c_int) !void {
    if (errno < 0) {
        const err = c.git_error_last();
        // TODO: this looks terrible. save to buf or something
        std.log.err(
            "libgit2 error: {}/{}: {s}",
            .{ errno, err.*.klass, err.*.message },
        );
        return error.GitError;
    }
}
