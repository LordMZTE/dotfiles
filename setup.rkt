#!/usr/bin/racket
#lang racket

;; Script for setting up the config.

(require racket/runtime-path)

;; Default output path
(define output-bin-path (make-parameter (build-path (find-system-path 'home-dir) ".local")))

;; Whether to log calls or not
(define log-calls (make-parameter #t))

;; Valid verbs
(define verbs '(install-scripts install-lsps-paru setup-nvim-config confgen))

(define verb
  (command-line
   #:program "setup.rkt"
   #:usage-help "Sets up my dotfiles. Available verbs:"
   "install-scripts, install-lsps-paru, setup-nvim-config, confgen"
   #:once-each [("-o" "--bin-output") o "Output directory for executables" (output-bin-path o)]
   #:args (verb)
   (string->symbol verb)))

;; Disable random printing of top-level stuff
(current-print void)

;; Set working directory to the location of the script
(begin
  (define-runtime-path script-dir ".")
  (current-directory script-dir))

;; Verify valid verb
(when (not (for/or ([valid-verb verbs])
             (symbol=? valid-verb verb)))
  (error "Invalid verb" verb))

(define (display-function-call func args)
  (when (log-calls)
    (printf "(~s ~a)\n" func (apply ~a #:separator " " args))))

;; Defines an alias to a function which will log it's parameters on invokation.
(define-syntax-rule (define-logging name func)
  (define (name . args)
    (display-function-call (quote name) args)
    (apply func args)))

(define-logging cmd (λ (exe . args) (apply system* (find-executable-path exe) args)))
(define-logging rm delete-directory/files)
(define-logging copy copy-directory/files)

(define (cmd/install-scripts)
  (define-logging mklink
    (λ (from to)
      (with-handlers ([exn:fail? (const #f)]) (delete-file to))
      (make-file-or-directory-link (normalize-path from) to)))

  (define-logging install-zig-script
    (λ (path)
      (parameterize ([current-directory path] [log-calls #f])
        (cmd "zig" "build" "-p" (output-bin-path) "-Doptimize=ReleaseFast"))))

  (mklink "scripts/map-touch-display.rkt" (build-path (output-bin-path) "bin" "map-touch-display"))
  (mklink "scripts/playvid.rkt" (build-path (output-bin-path) "bin" "playvid"))
  (mklink "scripts/start-joshuto.sh" (build-path (output-bin-path) "bin" "start-joshuto"))
  (mklink "scripts/startriver.sh" (build-path (output-bin-path) "bin" "startriver"))
  (mklink "scripts/update-nvim-plugins.rkt"
          (build-path (output-bin-path) "bin" "update-nvim-plugins"))
  (mklink "scripts/withjava.sh" (build-path (output-bin-path) "bin" "withjava"))

  (install-zig-script "scripts/mzteinit")
  (install-zig-script "scripts/openbrowser")
  (install-zig-script "scripts/playtwitch")
  (install-zig-script "scripts/prompt")
  (install-zig-script "scripts/randomwallpaper")
  (install-zig-script "scripts/vinput")
  null)

(define (cmd/install-lsps-paru)
  (define lsp-packages
    (list "elixir-ls-git"
          "eslint"
          "jdtls"
          "lua-language-server"
          "shellcheck"
          "shfmt"
          "taplo-cli"
          "tidy"
          "vscode-langservers-extracted"
          "yaml-language-server"
          "zls-git"))

  (apply cmd "paru" "-S" "--needed" "--noconfirm" lsp-packages)

  (when (find-executable-path "opam")
    (cmd "opam" "install" "--yes" "ocaml-lsp-server" "ocamlformat"))
  null)

(define (cmd/setup-nvim-config)
  (define nvim-config-dir (build-path (find-system-path 'home-dir) ".config" "nvim"))
  (rm nvim-config-dir)
  (copy "mzte-nv/conf" nvim-config-dir)
  (cmd "mzte-nv-compile" (path->string nvim-config-dir))
  null)

(define (cmd/confgen)
  (rm "cgout")
  (cmd "confgen" "confgen.lua" "cgout")
  null)

(case verb
  [(install-scripts) (cmd/install-scripts)]
  [(install-lsps-paru) (cmd/install-lsps-paru)]
  [(setup-nvim-config) (cmd/setup-nvim-config)]
  [(confgen) (cmd/confgen)])
