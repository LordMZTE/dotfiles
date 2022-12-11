local nullls = require "null-ls"

nullls.setup {
    sources = {
        nullls.builtins.code_actions.gitsigns,
        nullls.builtins.code_actions.shellcheck,
        nullls.builtins.diagnostics.fish,
        nullls.builtins.diagnostics.shellcheck,
        nullls.builtins.diagnostics.tidy,
        nullls.builtins.formatting.clang_format,
        nullls.builtins.formatting.fish_indent,
        nullls.builtins.formatting.prettier,
        nullls.builtins.formatting.shfmt,
        nullls.builtins.formatting.stylua,
        nullls.builtins.formatting.tidy,
    },
}