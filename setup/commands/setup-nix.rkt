#lang racket
(require "../common.rkt")
(provide run)

(define (run)
  (cmd "nix" "profile" "install" ".#mzte-nix" "--impure")
  (cmd "nix" "build" ".#cgnix" "--impure" "--out-link" "nix/cgnix/nix.lua"))
