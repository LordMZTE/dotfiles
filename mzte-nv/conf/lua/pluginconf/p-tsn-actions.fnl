(local (mztenv tsna tsna-actions tsna-helpers nullls)
       (values (require :mzte_nv) (require :ts-node-action)
               (require :ts-node-action.actions)
               (require :ts-node-action.helpers) (require :null-ls)))

(local zig-padding {")" " %s"
                    "]" " %s"
                    "}" " %s"
                    "{" "%s "
                    "," "%s "
                    := " %s "
                    :+ " %s "
                    :- " %s "
                    :* " %s "
                    :/ " %s "
                    :** " %s "
                    :++ " %s "})

(tsna.setup {:zig {:FnCallArguments (tsna-actions.toggle_multiline zig-padding)
                   :InitList (tsna-actions.toggle_multiline zig-padding)
                   :VarDecl [{1 #(mztenv.tsn_actions.zigToggleMutability (tsna-helpers.node_text $1))
                              :name "Toggle Mutability"}]}})

(nullls.register {:name :TSNA
                  :method [(. nullls :methods :CODE_ACTION)]
                  :filetypes [:_all]
                  :generator {:fn (. tsna :available_actions)}})

(vim.keymap.set :n :U (. tsna :node_action) {:noremap true :silent true})
