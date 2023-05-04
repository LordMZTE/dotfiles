#!/usr/bin/env racket
#lang racket

;; This script is used to map the xinput device(s) of my external touch
;; display to the corresponding X screen.

(define screen (command-line #:args (screen) screen))

(define cmd-outp (with-output-to-string (λ () (system* (find-executable-path "xinput") "--list"))))

(for ([line (string-split cmd-outp "\n")] #:when (string-contains? line "TSTP MTouch"))
  (match-define (list _ id) (regexp-match #px"id=(\\d+)" line))
  (system* (find-executable-path "xinput") "map-to-output" id screen))
