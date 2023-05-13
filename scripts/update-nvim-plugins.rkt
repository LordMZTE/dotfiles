#!/usr/bin/env racket
#lang racket

;; Updates the neovim plugins
;; Packer is currently too dumb to do this is the plugins have been compiled

(define plugin-dir (expand-user-path "~/.local/share/nvim/site/pack/packer"))

(define dirs
  (map (λ (path) (match-let-values ([(p _ _) (split-path path)]) p))
       (find-files (λ (path) (equal? (path->string (last (explode-path path))) ".git")) plugin-dir)))

(define git-path (find-executable-path "git"))

(for ([dir (in-list dirs)])
  (let ([name (last (explode-path dir))]) (printf "\n====== ~a ======\n\n" name))
  (parameterize ([current-directory dir])
    (system* git-path "checkout" "." #:set-pwd? #t)
    (system* git-path "pull" #:set-pwd? #t)))

(displayln "\n====== COMPILING ======\n")
(system* (find-executable-path "mzte-nv-compile") plugin-dir)
(void)