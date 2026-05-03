(local arborist (require :arborist))

(local overrides
       {:confgen {:url "https://git.mzte.de/LordMZTE/tree-sitter-confgen.git"}})

(arborist.setup {;; Who even though putting something so performance critical that it even lags
                 ;; your editor sometimes into a VM rather than highly optimized native code is a
                 ;; good idea?  People...
                 :prefer_wasm false
                 :install_popular false
                 : overrides})
