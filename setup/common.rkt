#lang racket

(provide define-logging
         log-calls
         output-bin-path
         cmd
         rm
         copy
         generate-cgopt-json
         install-zig
         install-rust
         install-roswell)

;; Whether to log calls or not
(define log-calls (make-parameter #t))

;; Default output path
(define output-bin-path (make-parameter (build-path (find-system-path 'home-dir) ".local")))

(define (display-function-call func args)
  (when (log-calls)
    (fprintf (current-error-port)
             "\x1b[1;30m(\x1b[1;32m~s\x1b[1;33m~a\x1b[1;30m)\x1b[0m\n"
             func
             (string-append (if (null? args) "" " ") (apply ~a #:separator " " args)))))

;; Defines an alias to a function which will log it's parameters on invokation.
(define-syntax-rule (define-logging name func)
  (define (name . args)
    (display-function-call (quote name) args)
    (apply func args)))

(define-logging cmd
  (λ (exe . args)
    (unless (apply system* (find-executable-path exe) args)
      (raise-user-error "Command Failed"))))
(define-logging rm delete-directory/files)
(define-logging copy copy-directory/files)

(define-logging install-zig
  (λ (path [mode "ReleaseFast"])
    (parameterize ([current-directory path] [log-calls #f])
      (cmd "zig" "build" "-p" (output-bin-path) (string-append "-Doptimize=" mode)))))

(define-logging install-rust
  (λ (path)
    (parameterize ([current-directory path] [log-calls #f])
      (cmd "cargo"
           "-Z"
           "unstable-options"
           "build"
           "--release"
           "--out-dir"
           (build-path (output-bin-path) "bin")))))

(define-logging generate-cgopt-json
  (λ ()
    (unless (directory-exists? "cgout")
      (make-directory "cgout"))
    (call-with-output-file*
     #:exists 'truncate/replace
     "cgout/opts.json"
     (λ (outfile)
       (parameterize ([log-calls #f] [current-output-port outfile])
         (cmd "confgen" "--json-opt" "confgen.lua"))))))

(define-logging
  install-roswell
  (λ (path)
    (parameterize ([log-calls #f])
      (match-let*-values ([(_ filename _) (split-path path)]
                          [(outpath)
                           (build-path (output-bin-path) "bin" (path-replace-extension filename ""))])
                         (cmd "ros" "dump" "executable" path "-o" outpath)))))
