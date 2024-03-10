{ pkgs, confgen, zig_0_12 }:
let
  deps = pkgs.linkFarm "zig-packages" [
    # ansi-term
    {
      name = "1220ea86ace34b38e49c1d737c5f857d88346af10695a992b38e10cb0a73b6a19ef7";
      path = pkgs.fetchgit {
        url = "https://github.com/LordMZTE/ansi-term.git";
        rev = "73c03175068679685535111dbea72cade075719e";
        hash = "sha256-YeCZPUNciJz141HSHk4kBIfVYW/JqLflkKCjRHhIORk=";
      };
    }
  ];
in
pkgs.stdenv.mkDerivation {
  name = "mzteinit";
  # TODO: WTF
  src = ./../..;
  dontBuild = true;
  dontFixup = true;

  configurePhase = ''
    mkdir cgout
    # TODO: WTF
    sed -i 's#/usr/share/lua/5.4/fennel.lua#${pkgs.luajitPackages.fennel}/share/lua/5.1/fennel.lua#' confgen.lua
    ${confgen.default}/bin/confgen --json-opt confgen.lua > cgout/opts.json
  '';

  postPatch = ''
    cd scripts/mzteinit
    export ZIG_LOCAL_CACHE_DIR=$(pwd)/zig-cache
    export ZIG_GLOBAL_CACHE_DIR=$ZIG_LOCAL_CACHE_DIR
    mkdir -p $ZIG_GLOBAL_CACHE_DIR
    ln -s ${deps} $ZIG_GLOBAL_CACHE_DIR/p
    cd ../..
  '';

  installPhase = ''
    cd scripts/mzteinit
    runHook preBuild
    ${zig_0_12}/bin/zig build install --prefix $out
    runHook postBuild
    cd ../..
  '';

  passthru.shellPath = "/bin/mzteinit";
}
