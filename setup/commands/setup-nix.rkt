#lang racket
(require "../common.rkt")
(provide run)

(define (run)
  (cmd "nix" "build" ".#cgnix" "--impure" "--out-link" "nix/cgnix/nix.lua"))
