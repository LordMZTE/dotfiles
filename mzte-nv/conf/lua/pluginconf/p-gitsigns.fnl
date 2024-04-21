(local gitsigns (require :gitsigns))

(fn on-attach [bufnr]
  (print :attached bufnr)
  (vim.keymap.set :n :gV
                  (fn []
                    (gitsigns.toggle_deleted)
                    (gitsigns.toggle_numhl)
                    (gitsigns.toggle_linehl)
                    (gitsigns.toggle_word_diff)
                    (gitsigns.toggle_current_line_blame))
                  {:buffer bufnr}))

(gitsigns.setup {:on_attach on-attach})
