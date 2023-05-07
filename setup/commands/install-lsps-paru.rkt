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

  ;; install OCaml LSP
  (when (find-executable-path "opam")
    (cmd "opam" "install" "--yes" "ocaml-lsp-server" "ocamlformat"))

  ;; Install CommonLisp LSP
  ;; Also useful for CommonLisp: `ros install koji-kojiro/cl-repl`
  (when (find-executable-path "ros")
    (cmd "ros" "install" "lem-project/lem" "cxxxr/cl-lsp"))
  null)
