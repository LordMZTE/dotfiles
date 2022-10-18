lsps := "
eslint
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
        `pwd`/scripts/{start-joshuto,withjava} \
        {{target}}/bin

    cd scripts/randomwallpaper && zig build -Drelease-fast -p {{target}}
    cd scripts/vinput && zig build -Drelease-fast -p {{target}}
    cd scripts/playtwitch && gyro build -Drelease-fast -p {{target}}
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
    cd mzte_nv && zig build -Drelease-fast
    cp mzte_nv/zig-out/lib/libmzte_nv.so ~/.local/share/nvim/mzte_nv.so
