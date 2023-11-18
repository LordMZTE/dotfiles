#!/usr/bin/env racket
#lang racket

(current-print void)

(define sysfs (make-parameter #t))
(define ddc (make-parameter #t))
(define brightness
  (command-line #:program "brightness"
                #:usage-help "Sets the backlight brightness of connected monitors"
                #:once-each
                [("-s" "--no-sysfs") "Don't set brightness via sysfs" (sysfs #f)]
                [("-d" "--no-ddc") "Don't set brightness via DDC/CI" (ddc #f)]
                #:args (brightness-arg)
                (let ([brightness-parsed (string->number brightness-arg)])
                  (unless ((and/c (>=/c 0) (<=/c 100)) brightness-parsed)
                    (raise-user-error "brightness argument is invalid!"))
                  brightness-parsed)))

(when (sysfs)
  (for ([dir (directory-list "/sys/class/backlight")])
    (printf "sysfs: ~a\n" dir)
    (let* ([max-brightness (string->number (file->string (build-path dir "max_brightness")))]
           [rel-brightness (exact-round (* brightness (/ max-brightness 100)))]
           [brightness-path (build-path dir "brightness")])
      (display-to-file rel-brightness brightness-path #:exists 'truncate))))

(match* ((ddc) (find-executable-path "ddcutil"))
  [(#f _) #f]
  [(_ #f) #f]
  [(_ ddcutil-exe)
   (for ([dpy (regexp-match* #px"Display (\\d+)"
                             (car (process* ddcutil-exe "detect"))
                             #:match-select (λ (m) (string->number
                                                    (bytes->string/utf-8 (cadr m)))))])
     (printf "ddc: #~a\n" dpy)
     (system* ddcutil-exe "setvcp" "10" (format "--display=~a" dpy) (number->string brightness)))])
