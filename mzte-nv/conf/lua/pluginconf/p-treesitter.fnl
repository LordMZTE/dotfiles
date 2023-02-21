(local (configs parsers ts-utils)
       (values (require :nvim-treesitter.configs)
               (require :nvim-treesitter.parsers)
               (require :nvim-treesitter.ts_utils)))

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

(fn delete-node-under-cursor []
  (local (r1 c1 r2 c2)
         (vim.treesitter.get_node_range (ts-utils.get_node_at_cursor)))
  (vim.api.nvim_buf_set_text 0 r1 c1 r2 c2 []))

;; Shorthand for deleting the TS node under the cursor
(vim.keymap.set :n :D delete-node-under-cursor {:noremap true :silent true})
