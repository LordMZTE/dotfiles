#!/usr/bin/env racket
#lang racket

;; Plays a random file in CWD using mpv, unless one is provided as CLI arg.
;; Asks to delete the file after viewing it.

(require racket/gui/base)

(current-print void)

(define file
  ;; default to random file
  (command-line #:args ([f
                         (let ([dir (filter file-exists? (directory-list))])
                           (path->string (list-ref dir (random (length dir)))))])
                f))

(printf "playing: ~a\n" file)
(system* (find-executable-path "mpv") file)

(when (eq? (message-box "Delete Video?" (format "Delete this video?\n\n~a" file) #f '(yes-no)) 'yes)
  (printf "deleting `~a`\n" file)
  (delete-file file))
