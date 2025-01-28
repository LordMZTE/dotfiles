(local tterm (require :toggleterm))

(tterm.setup {:open_mapping :<C-t>
              :direction :vertical
              :size (fn [term]
                      (if (= term.direction :horizontal) 12
                          (* vim.o.columns 0.4)))})
