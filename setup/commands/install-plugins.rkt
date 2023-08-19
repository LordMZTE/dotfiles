#lang racket
(require "../common.rkt")
(provide run)

(define (run)
  (install-zig "plugins/mpv-sbskip")
  (build-haxe "plugins/tampermonkey-mzte-css"))
