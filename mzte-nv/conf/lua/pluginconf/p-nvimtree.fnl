(local nvtree (require :nvim-tree))

(nvtree.setup {:actions {:change_dir {:global true}}
               :view {:adaptive_size true}
               :diagnostics {:enable true}
               :git {;; don't hide .gitignored files
                     :ignore false}
               :renderer {:indent_markers {:enable true} :group_empty true}})

;; open on startup
(fn on-enter [data]
  (local is-no-name (and (= data.file "") (= (. vim :bo data.buf :buftype) "")))
  (local is-dir (= (vim.fn.isdirectory data.file) 1))
  (when is-dir
    (vim.cmd.cd data.file))
  (when (or is-no-name is-dir)
    ((. (require :nvim-tree.api) :tree :open))))

(vim.api.nvim_create_autocmd [:VimEnter] {:callback on-enter})

(vim.keymap.set :n :TT #((. (require :nvim-tree.api) :tree :toggle))
                (. (require :mzte_nv) :utils :map_opt))
