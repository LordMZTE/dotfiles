const std = @import("std");

pub const c = @cImport({
    @cInclude("git2.h");
});

pub fn checkGitError(errno: c_int) !void {
    if (errno < 0) {
        const err = c.git_error_last();
        std.log.err(
            "libgit2 error: {}/{}: {s}",
            .{ errno, err.*.klass, err.*.message },
        );
        return error.GitError;
    }
}
