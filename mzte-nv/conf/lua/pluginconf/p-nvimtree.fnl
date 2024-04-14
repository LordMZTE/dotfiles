(local nvtree (require :nvim-tree))

(nvtree.setup {:actions {:change_dir {:global true}}
               :view {:adaptive_size true}
               :diagnostics {:enable true}
               :git {;; don't hide .gitignored files
                     :ignore false}
               :renderer {:indent_markers {:enable true} :group_empty true}})

(vim.keymap.set :n :TT #((. (require :nvim-tree.api) :tree :toggle))
                (. (require :mzte_nv) :utils :map_opt))
