(local (mztenv configs parsers ts-utils)
       (values (require :mzte_nv)
               (require :nvim-treesitter.configs)
               (require :nvim-treesitter.parsers)
               (require :nvim-treesitter.ts_utils)))

;; Nix based parsers
(let [path mztenv.reg.tree_sitter_parsers]
  (when path
    (vim.opt.runtimepath:prepend path)))

(var parser-config (parsers.get_parser_configs))

(tset parser-config :haxe {:install_info {:url "https://github.com/vantreeseba/tree-sitter-haxe"
                                          :files [:src/parser.c :src/scanner.c]
                                          :branch :main}
                           :filetype :haxe})

(local install-dir (.. (vim.loop.os_homedir) :/.local/share/nvim/ts-parsers))
(vim.opt.runtimepath:append install-dir)

(configs.setup {:parser_install_dir install-dir
                :highlight {:enable true}
                :autotag {:enable true}
                :indent {:enable true}
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

(let [mopt (. (require :mzte_nv) :utils :map_opt)]
  ;; Shorthand for deleting the TS node under the cursor
  (vim.keymap.set :n :D delete-node-under-cursor mopt)
  ;; Shorthand for deleting the TS node under the cursor and switching to insert mode
  (vim.keymap.set :n :C
                  (fn [] (delete-node-under-cursor) (vim.cmd.startinsert)) mopt))
