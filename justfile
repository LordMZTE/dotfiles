lsps := "
elixir-ls-git
eslint
jdtls
lua-language-server
rust-analyzer
shellcheck
shfmt
taplo-cli
tidy
vscode-langservers-extracted
yaml-language-server
zls-bin
"

install-scripts target=(`echo $HOME` + "/.local"):
    ln -sf \
        `pwd`/scripts/{start-joshuto,withjava,startriver} \
        {{target}}/bin

    cd scripts/randomwallpaper && zig build -Drelease-fast -p {{target}}
    cd scripts/vinput && zig build -Drelease-fast -p {{target}}
    cd scripts/playtwitch && zig build -Drelease-fast -p {{target}}
    cd scripts/openbrowser && zig build -Drelease-fast -p {{target}}
    cd scripts/prompt && gyro build -Drelease-fast -p {{target}}
    cd scripts/mzteinit && gyro build -Drelease-fast -p {{target}}

install-lsps-paru:
    #!/bin/sh
    paru -S --needed --noconfirm {{replace(lsps, "\n", " ")}}

    cargo install prosemd-lsp

    if which opam &> /dev/null; then
        opam install --yes \
            ocaml-lsp-server \
            ocamlformat
    fi


install-mzte-nv:
    cd mzte-nv && zig build -Drelease-fast -p ~/.local

setup-nvim-config: install-mzte-nv
    rm -rf ~/.config/nvim
    cp -r mzte-nv/conf ~/.config/nvim
    mzte-nv-compile ~/.config/nvim
