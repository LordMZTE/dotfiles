(local ufo (require :ufo))

(fn lsp-folds? [bufnr]
  (accumulate [has false _ client (ipairs (vim.lsp.get_clients {: bufnr}))
               &until has]
    (not= client.server_capabilities.foldingRangeProvider nil)))

(fn treesitter? [ft]
  (let [lang (vim.treesitter.language.get_lang ft)
        (have-ts _) (pcall vim.treesitter.language.inspect lang)]
    have-ts))

(ufo.setup {:open_fold_hl_timeout 0
            :provider_selector (fn [bufnr ft _]
                                 (if (lsp-folds? bufnr) [:lsp :indent]
                                     (treesitter? ft) [:treesitter :indent]
                                     [:indent]))})

(tset vim :o :foldcolumn :0)
(tset vim :o :foldlevel 256)
(tset vim :o :foldlevelstart 256)
(tset vim :o :foldenable true)

(let [mopt (. (require :mzte_nv) :utils :map_opt)]
  ;; toggle fold
  (vim.keymap.set :n :zO ufo.openAllFolds mopt)
  (vim.keymap.set :n :zC ufo.closeAllFolds mopt))
