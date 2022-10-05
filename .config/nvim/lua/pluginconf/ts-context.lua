local tsc = require "treesitter-context"
tsc.setup {
    patterns = {
        zig = {
            "TopLevelDecl",
        },

        html = {
            "element",
        }
    },
}
