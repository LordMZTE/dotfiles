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

install-scripts target=(`echo $HOME` + "/.local/bin"): build-scripts
    cp scripts/randomwallpaper/zig-out/bin/randomwallpaper {{target}}/randomwallpaper
    cp scripts/playtwitch/zig-out/bin/playtwitch {{target}}/playtwitch
    cp scripts/mzteinit/zig-out/bin/mzteinit {{target}}/mzteinit

    ln -sf \
        `pwd`/scripts/{start-joshuto,withjava} \
        {{target}}


build-scripts:
    cd scripts/randomwallpaper && zig build -Drelease-fast
    cd scripts/playtwitch && gyro build -Drelease-fast
    cd scripts/mzteinit && gyro build -Drelease-fast

install-lsps-paru:
    #!/bin/sh
    paru -S --needed --noconfirm {{replace(lsps, "\n", " ")}}

    cargo install prosemd-lsp

    if which opam &> /dev/null; then
        opam install --yes \
            ocaml-lsp-server \
            ocamlformat
    fi

install-prompt:
    cd prompt/ && gyro build -Drelease-fast
    cp prompt/zig-out/bin/prompt ~/.local/bin
