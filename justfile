lsps := "
bash-language-server
lua-language-server
rust-analyzer
taplo-lsp
vscode-langservers-extracted
yaml-language-server
"

install-scripts target=(`echo $HOME` + "/.local/bin"):
    opam install --yes clap
    cd scripts/playtwitch && dune build
    chmod -R +w scripts/playtwitch
    cp scripts/playtwitch/_build/default/playtwitch.exe {{target}}/playtwitch

    ln -sf \
        `pwd`/scripts/{start-joshuto,withjava,randomwallpaper} \
        {{target}}

install-lsps-paru:
    #!/bin/sh
    paru -S --needed --noconfirm {{replace(lsps, "\n", " ")}}

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
