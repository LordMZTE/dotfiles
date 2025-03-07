{ common, pkgs, ... }:
let
  CGOPTS = "${common.confgenFile "cgassets/constsiz_opts.json"}";

  deps = pkgs.stdenvNoCC.mkDerivation {
    name = "mzte-scripts-packages";
    src = ./..;

    # TODO: broken
    outputHashMode = "recursive";
    outputHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    preferLocalBuild = true;

    nativeBuildInputs = with pkgs; [
      zig_0_14
    ];

    dontConfigure = true;

    env.ZIG_GLOBAL_CACHE_DIR = "$TMPDIR/zig-cache";

    buildPhase = ''
      zig build --fetch
    '';

    installPhase = ''
      mv "$ZIG_GLOBAL_CACHE_DIR/p" $out
    '';
  };
in
{
  output.packages.scripts = pkgs.stdenv.mkDerivation {
    name = "mzte-scripts";
    src = ./..;
    dontConfigure = true;

    nativeBuildInputs = with pkgs; [
      zig_0_13.hook

      pkg-config
      wayland-protocols
      wayland-scanner
    ];

    buildInputs = with pkgs; [
      libGL
      libgit2
      wayland
      mpv-unwrapped
    ];

    env = { inherit CGOPTS; };

    postPatch = ''
      ln -sf "${deps}" "$ZIG_GLOBAL_CACHE_DIR/p"
    '';
  };
}
