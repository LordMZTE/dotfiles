#lang racket
(require "../common.rkt")
(provide run)

(define (run)
  (define nvim-config-dir (build-path (find-system-path 'home-dir) ".config" "nvim"))
  (install-zig "mzte-nv")
  (rm nvim-config-dir)
  (copy "mzte-nv/conf" nvim-config-dir)
  (cmd "mzte-nv-compile" (path->string nvim-config-dir))
  null)
