#lang racket

(provide define-logging
         log-calls
         output-bin-path
         cmd
         rm
         copy)

;; Whether to log calls or not
(define log-calls (make-parameter #t))

;; Default output path
(define output-bin-path (make-parameter (build-path (find-system-path 'home-dir) ".local")))

(define (display-function-call func args)
  (when (log-calls)
    (printf "\x1b[1;30m(~s ~a)\x1b[0m\n" func (apply ~a #:separator " " args))))

;; Defines an alias to a function which will log it's parameters on invokation.
(define-syntax-rule (define-logging name func)
  (define (name . args)
    (display-function-call (quote name) args)
    (apply func args)))

(define-logging cmd (λ (exe . args) (apply system* (find-executable-path exe) args)))
(define-logging rm delete-directory/files)
(define-logging copy copy-directory/files)
