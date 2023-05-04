#lang racket
(require "../common.rkt")
(provide run)

(define (run)
  (rm "cgout")
  (cmd "confgen" "confgen.lua" "cgout")
  null)
