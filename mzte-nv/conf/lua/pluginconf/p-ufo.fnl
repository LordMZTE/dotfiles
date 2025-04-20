(local (ufo ts-parsers)
       (values (require :ufo) (require :nvim-treesitter.parsers)))

(fn lsp-folds? [bufnr]
  (accumulate [has false _ client (ipairs (vim.lsp.get_clients {: bufnr}))
               &until has]
    (not= client.server_capabilities.foldingRangeProvider nil)))

(ufo.setup {:open_fold_hl_timeout 0
            :provider_selector (fn [bufnr ft _]
                                 (if (lsp-folds? bufnr) [:lsp :indent]
                                     (ts-parsers.has_parser ft) [:treesitter
                                                                 :indent]
                                     [:indent]))})

(tset vim :o :foldcolumn :0)
(tset vim :o :foldlevel 256)
(tset vim :o :foldlevelstart 256)
(tset vim :o :foldenable true)

(let [mopt (. (require :mzte_nv) :utils :map_opt)]
  ;; toggle fold
  (vim.keymap.set :n :t :za mopt)
  (vim.keymap.set :n :zO ufo.openAllFolds mopt)
  (vim.keymap.set :n :zC ufo.closeAllFolds mopt))
