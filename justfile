install-scripts target="$HOME/.local/bin":
    #!/bin/sh
    zig build-exe \
        -lc -lX11 -lXinerama \
        scripts/randomwallpaper.zig \
        -femit-bin={{target}}/randomwallpaper
    ln -sf \
        `pwd`/scripts/{playtwitch,start-joshuto,withjava} \
        {{target}}
