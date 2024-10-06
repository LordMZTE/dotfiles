#!/usr/bin/env racket
#lang racket

;; Script for setting up the config.

(require racket/runtime-path
         "setup/common.rkt")

;; Valid verbs
(define verbs '(install-scripts install-plugins install-lsps-paru setup-nvim-config setup-nix run-confgen))

(define verb
  (command-line #:program "setup.rkt"
                #:usage-help "Sets up my dotfiles. Available verbs:"
                "install-scripts, install-plugins, setup-nix, setup-nvim-config, run-confgen"
                #:once-each
                [("-o" "--bin-output") o "Output directory for executables" (output-bin-path o)]
                #:args (verb)
                (string->symbol verb)))

;; Disable random printing of top-level stuff
(current-print void)

;; Set working directory to the location of the script
(begin
  (define-runtime-path script-dir ".")
  (current-directory script-dir))

;; Verify valid verb
(unless (for/or ([valid-verb verbs])
          (symbol=? valid-verb verb))
  (raise-user-error "Invalid verb" verb))

;; Load local config
(load-config)

(match verb
  ['install-scripts
   (local-require "setup/commands/install-scripts.rkt")
   (run)]
  ['setup-nvim-config
   (local-require "setup/commands/setup-nvim-config.rkt")
   (run)]
  ['setup-nix
   (local-require "setup/commands/setup-nix.rkt")
   (run)]
  ['run-confgen
   (local-require "setup/commands/run-confgen.rkt")
   (run)])
