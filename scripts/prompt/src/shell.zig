const setup_fmtstrs = struct {
    const fish =
        \\functions -e fish_mode_prompt
        \\function fish_prompt
        \\    set -x MZPROMPT_SHELL fish
        \\    set -x MZPROMPT_STATUS $status
        \\    set -x MZPROMPT_VI_MODE $fish_bind_mode
        \\    set -x MZPROMPT_DURATION $CMD_DURATION
        \\    set -x MZPROMPT_JOBS (count (jobs))
        \\    {[argv0]s} show
        \\end
        \\
    ;
    const nu =
        \\$env.PROMPT_COMMAND = {{ ||
        \\    $env.MZPROMPT_SHELL = "nu"
        \\    $env.MZPROMPT_STATUS = $env.LAST_EXIT_CODE
        \\    $env.MZPROMPT_VI_MODE = "_none"
        \\    $env.MZPROMPT_DURATION = $env.CMD_DURATION_MS
        \\    $env.MZPROMPT_JOBS = 0
        \\    {[argv0]s} show
        \\}}
        \\
        \\$env.PROMPT_COMMAND_RIGHT = ""
        \\
        \\$env.PROMPT_INDICATOR = ""
        \\$env.PROMPT_INDICATOR_VI_INSERT = ""
        \\$env.PROMPT_INDICATOR_VI_NORMAL = "〉"
        \\$env.PROMPT_MULTILINE_INDICATOR = "::: "
        \\$env.PROMPT_INDICATOR = ""
        \\
    ;
    const bash =
        \\__mzprompt_show() {{
        \\    export MZPROMPT_STATUS="$?"
        \\    export MZPROMPT_SHELL="bash"
        \\    export MZPROMPT_VI_MODE="_none"
        \\    export MZPROMPT_DURATION=0
        \\    export MZPROMPT_JOBS=$1
        \\    {[argv0]s} show
        \\}}
        \\PS1='$(__mzprompt_show \j)'
        \\
    ;
};

pub const Shell = enum {
    fish,
    nu,
    bash,

    pub fn writeInitCode(self: Shell, argv0: []const u8, writer: anytype) !void {
        switch (self) {
            inline else => |s| {
                const fmt = @field(setup_fmtstrs, @tagName(s));
                try writer.print(fmt, .{ .argv0 = argv0 });
            },
        }
    }
};
