lsps := "
gitlint
lua-language-server
rust-analyzer
shellcheck
shfmt
taplo-cli
vscode-langservers-extracted
yaml-language-server
"

install-scripts target=(`echo $HOME` + "/.local/bin"): build-scripts
    cp scripts/randomwallpaper/target/release/randomwallpaper {{target}}/randomwallpaper
    cp scripts/playtwitch/zig-out/bin/playtwitch {{target}}/playtwitch

    ln -sf \
        `pwd`/scripts/{start-joshuto,withjava} \
        {{target}}


build-scripts:
    cargo build --release --manifest-path scripts/randomwallpaper/Cargo.toml
    cd scripts/playtwitch && zig build -Drelease-fast

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
    RUSTFLAGS="-C target-cpu=native" cargo build --release \
        --manifest-path prompt/Cargo.toml
    strip prompt/target/release/prompt
    cp prompt/target/release/prompt ~/.local/bin
