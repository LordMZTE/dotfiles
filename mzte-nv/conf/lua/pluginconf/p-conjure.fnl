;; Blame conjure for this BS config
;; NOTE: this is ran before conjure initialization

;; Disable auto-attach
(tset vim :g "conjure#client_on_load" false)

(tset vim :g "conjure#mapping#prefix" :<F1>)

;; Only enable used clients
(tset vim :g "conjure#filetypes" [:clojure
                                  :fennel
                                  :racket
                                  :scheme
                                  :lua
                                  :python])
(tset vim :g "conjure#filetype#rust" false)
(tset vim :g "conjure#filetype#lisp" false)

;; This has custom handling for compat with LSP
(tset vim :g "conjure#mapping#doc_word" false)
