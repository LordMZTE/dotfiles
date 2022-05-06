local nullls = require "null-ls"

nullls.setup {
    sources = {
        nullls.builtins.code_actions.gitsigns,
        nullls.builtins.code_actions.shellcheck,
        nullls.builtins.diagnostics.fish,
        nullls.builtins.diagnostics.gitlint.with {
            filetypes = { "gitcommit", "NeogitCommitMessage" },
        },
        nullls.builtins.diagnostics.shellcheck,
        nullls.builtins.formatting.fish_indent,
        nullls.builtins.formatting.shfmt,
        nullls.builtins.formatting.stylua,
    },
}
