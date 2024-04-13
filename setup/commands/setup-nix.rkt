#lang racket
(require "../common.rkt")
(provide run)

(define (run)
  (define out (build-path (find-system-path 'home-dir) ".local" "mzte-nix"))
  (cmd "nix" "build" ".#mzte-nix" "--impure" "--out-link" out)
  (cmd "nix" "build" ".#cgnix" "--impure" "--out-link" "nix/cgnix/nix.lua"))
