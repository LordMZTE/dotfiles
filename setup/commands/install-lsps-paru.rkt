#lang racket
(require "../common.rkt")
(provide run)

(define (run)
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
