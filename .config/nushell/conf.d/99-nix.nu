# Build a flake reference on a remote host. Creates a `result` symlink.
# The nix-command and flakes experimental features must be active both locally and on the target host.
def "nix rbuild" [
    host:string,       # The remote host to build on
    flakeref:string,   # A flake reference to build
    ...nixargs:string, # Additional arguments to pass to the eval command
    --drv(-d),         # Don't eval but treat flakeref as path to .drv file
    --no-link(-n),     # Don't create a `result` link
    --nom,             # Invoke `nom` on the remote machine instead of `nix`
    --remote-eval(-r), # Evaluate the derivation on the remote. Note that this will incorrectly handle path-based flake references.
]: nothing -> list<string> {
    let outpaths = if $remote_eval {
        print "Eval & Build on Remote..."
        ssh $host $"(if $nom { "nom" } else { "nix" }) build --no-link --print-out-paths '($flakeref)' ($nixargs | str join ' ')" | lines
    } else {
        let drv_path = if $drv { $flakeref } else {
            print "Eval..."
            let eval_output = nix eval $flakeref ...$nixargs
            if $eval_output =~ "error:" {
                error make {
                    msg: "Derivation evaluation failed!",
                    help: $eval_output,
                } | return $in
            }
            $eval_output | parse "«derivation {drv}»" | get 0.drv
        }

        print "Copy drv to Remote..."
        nix copy --substitute-on-destination --derivation --to $"ssh://($host)" $drv_path

        print "Build on Remote..."
        ssh $host $"(if $nom { "nom" } else { "nix" }) build --no-link --print-out-paths '($drv_path)^*'" | lines
    }

    print "Copy from Remote..."
    nix copy --substitute-on-destination --no-check-sigs --from $"ssh://($host)" ...$outpaths

    $outpaths
}

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
