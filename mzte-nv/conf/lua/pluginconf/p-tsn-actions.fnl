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

(macro md-marker-fn [level]
  `[{1 (fn [_#] ,(string.rep "#" level)) :name ,(.. "Convert to H" level)}])

(tsna.setup {:zig {:FnCallArguments (tsna-actions.toggle_multiline zig-padding)
                   :InitList (tsna-actions.toggle_multiline zig-padding)
                   :VarDecl [{1 #(mztenv.tsn_actions.zigToggleMutability (tsna-helpers.node_text $1))
                              :name "Toggle Mutability"}]}
             :markdown {:atx_h1_marker (md-marker-fn 2)
                        :atx_h2_marker (md-marker-fn 3)
                        :atx_h3_marker (md-marker-fn 4)
                        :atx_h4_marker (md-marker-fn 5)
                        :atx_h5_marker (md-marker-fn 6)
                        :atx_h6_marker (md-marker-fn 1)}})

(nullls.register {:name :TSNA
                  :method [(. nullls :methods :CODE_ACTION)]
                  :filetypes [:_all]
                  :generator {:fn (. tsna :available_actions)}})

(vim.keymap.set :n :U (. tsna :node_action) {:noremap true :silent true})
