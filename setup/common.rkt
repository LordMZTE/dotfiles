#lang racket

(provide build-haxe
         cmd
         copy
         define-logging
         generate-cgopt-json
         install-link
         install-roswell
         install-rust
         install-zig
         load-config
         log-calls
         output-bin-path
         rm)

(define-namespace-anchor common-ns)
(define (load-config)
  (let ([path (expand-user-path "~/.config/mzte_localconf/setup-opts.rkts")])
    (if (file-exists? path)
        (parameterize ([current-namespace (namespace-anchor->namespace common-ns)])
          (load path))
        (fprintf (current-error-port) "no setup-opts found, skipping\n"))))

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
(define-syntax (define-logging stx)
  (syntax-case stx ()
    [(_ (name arg ...) body ...)
     (syntax-case (cons #'list
                        (map (λ (a) (if (list? (syntax->list a)) (car (syntax->list a)) a))
                             (syntax->list #'(arg ...))))
       ()
       [display-args
        #'(define (name arg ...)
            (display-function-call 'name display-args)
            body ...)])]
    [(_ (name arg ... . more) body ...)
     (syntax-case (cons #'list
                        (map (λ (a) (if (list? (syntax->list a)) (car (syntax->list a)) a))
                             (syntax->list #'(arg ...))))
       ()
       [display-args
        #'(define (name arg ... . more)
            (display-function-call 'name (append display-args more))
            body ...)])]
    [(_ name val)
     #'(define (name . args)
         (display-function-call 'name args)
         (apply val args))]))

;; Defines a script installer with a backing function.
(define-syntax (define-script-installer stx)
  (syntax-case stx ()
    [(_ (name script arg ...) body ...)
     (syntax-case (cons #'list
                        (map (λ (a) (if (list? (syntax->list a)) (car (syntax->list a)) a))
                             (syntax->list #'(script arg ...))))
       ()
       [display-args
        #'(define (name script arg ...)
            (display-function-call 'name display-args)
            body ...)])]
    [(_ (name script arg ... . more) body ...)
     (syntax-case (cons #'list
                        (map (λ (a) (if (list? (syntax->list a)) (car (syntax->list a)) a))
                             (syntax->list #'(script arg ...))))
       ()
       [display-args
        #'(define (name script arg ... . more)
            (display-function-call 'name (append display-args more))
            body ...)])]))

(define-logging (cmd exe . args)
  (unless (apply system* (find-executable-path exe) args)
    (raise-user-error "Command Failed")))

(define-logging (rm path) (delete-directory/files path #:must-exist? false))
(define-logging copy copy-directory/files)

(define-script-installer
  (install-zig path [mode "ReleaseFast"])
  (parameterize ([current-directory path] [log-calls #f])
    (cmd "zig" "build" "-p" (output-bin-path) (string-append "-Doptimize=" mode))))

(define-script-installer (install-link from to)
  (with-handlers ([exn:fail? (const #f)])
    (delete-file to))
  (make-file-or-directory-link (normalize-path from) to))

(define-script-installer (install-rust path)
  (parameterize ([current-directory path] [log-calls #f])
    (cmd "cargo"
         "-Z"
         "unstable-options"
         "build"
         "--release"
         "--out-dir"
         (build-path (output-bin-path) "bin"))))

(define-logging (build-haxe path)
  (parameterize ([current-directory path] [log-calls #f])
    (cmd "haxe" "build.hxml")))

(define-logging (generate-cgopt-json)
  (make-directory* "cgout/_cgfs")
  (call-with-output-file* #:exists 'truncate/replace
                          "cgout/_cgfs/opts.json"
                          (λ (outfile)
                            (parameterize ([log-calls #f] [current-output-port outfile])
                              (cmd "confgen" "--json-opt" "confgen.lua")))))

(define-script-installer (install-roswell path)
  (parameterize ([log-calls #f])
    (match-let*-values ([(_ filename _) (split-path path)]
                        [(outpath)
                         (build-path (output-bin-path) "bin" (path-replace-extension filename ""))])
                       (cmd "ros" "dump" "executable" path "-o" outpath))))
