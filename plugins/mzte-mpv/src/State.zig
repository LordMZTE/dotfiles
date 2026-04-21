const std = @import("std");

/// Pool of long running jobs that is only cleaned at shutdown.
job_pool: std.Io.Group,
