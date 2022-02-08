lsps := "
bash-language-server
lua-language-server
rust-analyzer
taplo-lsp
vscode-langservers-extracted
yaml-language-server
"

install-scripts target=(`echo $HOME` + "/.local/bin"):
    cd scripts && zig build-exe \
        -lc -lX11 -lXinerama \
        randomwallpaper.zig \
        -femit-bin={{target}}/randomwallpaper

    opam install --yes clap
    cd scripts/playtwitch && dune build
    cp scripts/playtwitch/_build/default/playtwitch.exe {{target}}/playtwitch

    ln -sf \
        `pwd`/scripts/{start-joshuto,withjava} \
        {{target}}

install-lsps-paru:
    #!/bin/sh
    paru -S --needed --noconfirm {{replace(lsps, "\n", " ")}}

    if which opam &> /dev/null; then
        opam install --yes \
            ocaml-lsp-server \
            ocamlformat
    fi
