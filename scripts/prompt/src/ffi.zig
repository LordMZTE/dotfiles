const std = @import("std");
const c = @import("c");

pub fn checkGitError(errno: c_int) !void {
    if (errno < 0) {
        const err = c.git_error_last();
        if (err) |e| {
            std.log.err(
                "libgit2 error: {}/{}: {s}",
                .{ errno, e.*.klass, e.*.message },
            );
        } else {
            std.log.err("libgit2 error: {}", .{errno});
        }
        return error.GitError;
    }
}
