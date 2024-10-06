#lang racket
(require "../common.rkt")
(provide run)

(define (run)
  (define (bin-path bin)
    (build-path (output-bin-path) "bin" bin))

  (generate-cgopt-json)

  (cmd "zig" "build" "-Doptimize=ReleaseFast" "-p" (output-bin-path))
  null)
