(local tsc (require :treesitter-context))

(tsc.setup {:max_lines 8
            :patterns {:zig [:block
                             :FnProto
                             :function
                             :TopLevelDecl
                             :Statement
                             :IfStatement
                             :WhileStatement
                             :WhileExpr
                             :ForStatement
                             :ForExpr
                             :WhileStatement
                             :WhileExpr]
                       :html [:element]}})
