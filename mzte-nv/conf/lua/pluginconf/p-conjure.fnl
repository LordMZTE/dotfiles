;; Blame conjure for this BS config
(tset vim :g "conjure#mapping#prefix" :<F1>)

;; Only enable used clients
(tset vim :g "conjure#filetypes" [:clojure
                                  :fennel
                                  :racket
                                  :scheme
                                  :lua
                                  :lisp
                                  :python])

;; This has custom handling for compat with LSP
(tset vim :g "conjure#mapping#doc_word" false)
