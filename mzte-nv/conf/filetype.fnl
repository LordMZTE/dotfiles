(vim.filetype.add {:extension {:cgt (fn [path bufnr]
                                      (local trimmed (path:gsub :.cgt$ ""))
                                      (vim.filetype.match {:filename trimmed
                                                           : bufnr}))
                               ;; nvim defaults to scheme
                               :rkt :racket
                               :rktl :racket
                               :rktd :racket
                               ;; nvim doesn't know zon
                               :zon :zig
                               ;; Default to Common Lisp instead of just using generic Lisp
                               :lisp :commonlisp
                               ;; Roswell scripts
                               :ros :commonlisp
                               ;; Haxe
                               :hx :haxe
                               :hxml :hxml}})
