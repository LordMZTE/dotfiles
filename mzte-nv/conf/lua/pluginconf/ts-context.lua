local tsc = require "treesitter-context"
tsc.setup {
    patterns = {
        zig = {
            "block",
            "FnProto",
            "function",
            "TopLevelDecl",
            "Statement",
            "IfStatement",
            "WhileStatement",
            "WhileExpr",
            "ForStatement",
            "ForExpr",
            "WhileStatement",
            "WhileExpr",
        },

        html = {
            "element",
        }
    },
}
