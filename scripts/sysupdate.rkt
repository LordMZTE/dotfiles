#!/usr/bin/env racket
#lang racket

(current-print void)

(define noint (make-parameter #f))
(command-line #:program "sysupdate"
              #:usage-help "Update the system"
              #:once-each [("-n" "--noint") "Don't require user interaction" (noint #t)])

(define (cmd exe . args)
  (match (find-executable-path exe)
    [#f (printf "skipping command ~a, command not found\n" (cons exe args))]
    [exepath
     (printf ">>> ~a\n" (cons exe args))
     (apply system* exepath args)]))

(apply cmd (if (noint)
               '("paru" "-Syu" "--noconfirm")
               '("paru" "-Syu")))
(cmd "zupper" "update")
(cmd "rustup" "update")
(cmd "update-nvim-plugins")
(cmd "tldr" "--update")
