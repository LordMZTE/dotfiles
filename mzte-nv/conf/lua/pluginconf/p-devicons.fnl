(local wdi (require :nvim-web-devicons))

(local racket-icon {:icon "λ" :color "#9f1d20" :cterm_color 88 :name :Racket})
(local commonlisp-icon {:icon "λ"
                        :color "#3fb68b"
                        :cterm_color 49
                        :name :CommonLisp})

(wdi.setup {:override {:rkt racket-icon
                       :rktl racket-icon
                       :rktd racket-icon
                       :scm {:icon "λ"
                             :color "#3e5ba9"
                             :cterm_color 61
                             :name :Scheme}
                       :lisp commonlisp-icon
                       :ros commonlisp-icon}})
