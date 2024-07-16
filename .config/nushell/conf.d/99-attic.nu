def "attic bpush" [
    cache:string,      # The Attic cache to push to
    flake:string,      # The flake reference to build
    ...nixargs:string, # Extra arguments for Nix
    --nom(-n),         # Use Nom
] {
    let outpath = (^(if $nom { "nom" } else { "nix" })
                   build
                   --no-link
                   --print-out-paths
                   $flake
                   ...$nixargs)
    attic push $cache $outpath
}
