(local inlay-hint (require :inlay-hint))
(local mztenv (require :mzte_nv))

(fn display-cb [line-hints options bufnr winid]
  (if (> (length line-hints) 0)
      (let [(_ first-hint) (next line-hints)
            linenr (+ (. first-hint :position :line) 1)
            text-width (vim.fn.virtcol [linenr "$"] false winid)
            win-width (vim.fn.winwidth winid)
            avail-space (- win-width text-width 1)]
        (if (< avail-space mztenv.inlay_hint.min_avail_space) nil
            (do
              (table.sort line-hints
                          (fn [a b]
                            (< a.position.character b.position.character)))
              (mztenv.inlay_hint.formatHints line-hints avail-space))))
      nil))

(inlay-hint.setup {:virt_text_pos :right_align :display_callback display-cb})

