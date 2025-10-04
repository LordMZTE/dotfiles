(local M {})

(fn M.format [bufnr]
  (let [(have-nullls nullls-sources) (pcall require :null-ls.sources)
        fmt-sources (and have-nullls
                         (nullls-sources.get_available vim.bo.filetype
                                                       :NULL_LS_FORMATTING))
        format-with-nullls (and have-nullls (not= (length fmt-sources) 0))
        fmtopts (if format-with-nullls
                    {:filter (fn [client] (= client.name :null-ls))
                     :async true
                     : bufnr}
                    {:async true : bufnr})]
    (vim.lsp.buf.format fmtopts)))

M
