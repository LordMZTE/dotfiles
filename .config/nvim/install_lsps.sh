#!/bin/sh
set -e

paru -S --needed --noconfirm \
    bash-language-server \
    lua-language-server \
    rust-analyzer \
    taplo-lsp \
    vscode-langservers-extracted
