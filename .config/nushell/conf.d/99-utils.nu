def --env mkdircd [p: string] {
    mkdir $p
    cd $p
}

def wldd [path: string] {
    match (which $path) {
        [{ path: $p }] => { ldd $p },
        _ => { error make { msg: $"No external command ($path)" } },
    }
}

def viewdoc [f: path] {
    let inp = $f | path parse

    match $inp.extension {
        $e if $e in [ "doc", "docx", "odt", "ppt", "pptx", "odp" ] => {
            let outp = { extension: "pdf", parent: "/tmp", stem: $inp.stem } | path join
            libreoffice --convert-to pdf $f --outdir /tmp
            try { zathura $outp }
            rm $outp
        },
        "pdf" => { zathura $f },
        "html" => { openbrowser $"file://($f | path expand)" }
        $e if $e in [ "png", "webp", "jpg", "jpeg", "ff", "bmp" ] => { nsxiv $f },
        _ => { mpv $f },
    }
}

def pgrep [pattern: string]: nothing -> table<pid: int, ppid: int, name: string, status: string, cpu: float, mem: filesize, virtual: filesize> {
    ps | where name =~ $pattern
}
