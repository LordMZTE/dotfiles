(local (configs parsers)
       (values (require :nvim-treesitter.configs)
               (require :nvim-treesitter.parsers)))

(var parser-config (parsers.get_parser_configs))

(tset parser-config :haxe {:install_info {:url "https://github.com/vantreeseba/tree-sitter-haxe"
                                          :files [:src/parser.c]
                                          :branch :main}
                           :filetype :haxe})

(configs.setup {:highlight {:enable true}
                :autotag {:enable true}
                :indent {:enable true}
                :rainbow {:enable true
                          :hlgroups (fcollect [i 1 6] (.. :TSRainbow i))}
                :playground {:enable true}
                :incremental_selection {:enable true
                                        :keymaps {:init_selection :fv
                                                  :node_incremental :v
                                                  :node_decremental :V
                                                  :scope_incremental false}}})
