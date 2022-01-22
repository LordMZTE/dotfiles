#!/bin/sh
set -e

sudo npm i -g bash-language-server
paru -S --needed --noconfirm \
    vscode-langservers-extracted \
    rust-analyzer \
    lua-language-server \
    taplo-lsp
