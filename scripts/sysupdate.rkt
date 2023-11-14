#!/usr/bin/env racket
#lang racket

(current-print void)

(define noint (make-parameter #f))
(command-line #:program "sysupdate"
              #:usage-help "Update the system"
              #:once-each [("-n" "--noint") "Don't require user interaction" (noint #t)])

(define failures '())

(define (cmd exe . args)
  (match* ((find-executable-path exe) (cons exe args))
    [(#f argv) (printf "skipping command ~a, command not found\n" argv)]
    [(exepath argv)
     (printf ">>> ~a\n" argv)
     (unless (apply system* exepath args)
       (set! failures (cons argv failures)))]))

(apply cmd (if (noint)
               '("paru" "-Syu" "--noconfirm")
               '("paru" "-Syu")))
(cmd "zupper" "update")
(cmd "rustup" "update")
(cmd "update-nvim-plugins")
(cmd "tldr" "--update")

(unless (empty? failures)
  (raise-user-error "The following commands failed:" failures))
