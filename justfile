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
zls-git
"

install-scripts target=(`echo $HOME` + "/.local"):
    ln -sf \
        `pwd`/scripts/{map-touch-display,playvid,start-joshuto,withjava,startriver,update-nvim-plugins} \
        {{target}}/bin

    cd scripts/randomwallpaper && zig build -Doptimize=ReleaseFast -p {{target}}
    cd scripts/vinput && zig build -Doptimize=ReleaseFast -p {{target}}
    cd scripts/playtwitch && zig build -Doptimize=ReleaseFast -p {{target}}
    cd scripts/openbrowser && zig build -Doptimize=ReleaseFast -p {{target}}
    cd scripts/prompt && zig build -Doptimize=ReleaseFast -p {{target}}
    cd scripts/mzteinit && zig build -Doptimize=ReleaseFast -p {{target}}

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
    cd mzte-nv && zig build -Doptimize=ReleaseFast -p ~/.local

setup-nvim-config: install-mzte-nv
    rm -rf ~/.config/nvim
    cp -r mzte-nv/conf ~/.config/nvim
    mzte-nv-compile ~/.config/nvim

confgen:
    rm -rf cgout
    confgen confgen.lua cgout
