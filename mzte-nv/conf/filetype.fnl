(vim.filetype.add {:extension {:cgt (fn [path bufnr]
                                      (local trimmed (path:gsub :.cgt$ ""))
                                      (vim.filetype.match {:filename trimmed
                                                           : bufnr}))
                               ;; nvim defaults to scheme
                               :rkt :racket
                               :rktl :racket
                               :rktd :racket
                               ;; nvim doesn't know zon
                               :zon :zig}})
