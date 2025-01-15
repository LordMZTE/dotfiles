#lang racket
(require "../common.rkt")
(provide run)

(define (run)
  (let ([nix-cmd (if (find-executable-path "nom") "nom" "nix")])
    (cmd nix-cmd "build" ".#cgnix" "--impure" "--out-link" "nix/cgnix/nix.lua")))
