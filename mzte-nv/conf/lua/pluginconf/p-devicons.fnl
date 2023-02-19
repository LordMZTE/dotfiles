(local wdi (require :nvim-web-devicons))

(local racket-icon {:icon "λ" :color "#9f1d20" :cterm_color 88 :name :Racket})

(wdi.setup {:override {:rkt racket-icon
                       :rktl racket-icon
                       :rktd racket-icon
                       :scm {:icon "λ"
                             :color "#3e5ba9"
                             :cterm_color 61
                             :name :Scheme}}})
