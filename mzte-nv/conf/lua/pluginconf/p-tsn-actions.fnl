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

(local int-toggle-action {1 #(mztenv.tsn_actions.intToggle (tsna-helpers.node_text $1))
                          :name "Toggle Dec/Hex"})

(local int-to-hex-action {1 #(mztenv.tsn_actions.intToHex (tsna-helpers.node_text $1))
                          :name "Convert to Hex"})

(local int-to-dec-action {1 #(mztenv.tsn_actions.intToDec (tsna-helpers.node_text $1))
                          :name "Convert to Decimal"})

(tsna.setup {:zig {:FnCallArguments (tsna-actions.toggle_multiline zig-padding)
                   :InitList (tsna-actions.toggle_multiline zig-padding)
                   :VarDecl [{1 #(mztenv.tsn_actions.zigToggleMutability (tsna-helpers.node_text $1))
                              :name "Toggle Mutability"}]
                   :INTEGER [int-toggle-action]}
             :markdown {:atx_h1_marker (md-marker-fn 2)
                        :atx_h2_marker (md-marker-fn 3)
                        :atx_h3_marker (md-marker-fn 4)
                        :atx_h4_marker (md-marker-fn 5)
                        :atx_h5_marker (md-marker-fn 6)
                        :atx_h6_marker (md-marker-fn 1)}
             :java {:hex_integer_literal [int-to-dec-action]
                    :decimal_integer_literal [int-to-hex-action]}
             :c {:number_literal [int-toggle-action]}
             :cpp {:number_literal [int-toggle-action]}
             :lua {:number [int-toggle-action]}
             :fennel {:number [int-toggle-action]}})

(nullls.register {:name :TSNA
                  :method [(. nullls :methods :CODE_ACTION)]
                  :filetypes [:_all]
                  :generator {:fn (. tsna :available_actions)}})

(vim.keymap.set :n :U (. tsna :node_action)
                (. (require :mzte_nv) :utils :map_opt))
