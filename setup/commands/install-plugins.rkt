#lang racket
(require "../common.rkt")
(provide run)

(define (run)
  (install-zig "plugins/mzte-mpv")
  (build-haxe "plugins/tampermonkey-mzte"))
