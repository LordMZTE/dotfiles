{ common, pkgs, ... }:
let
  CGOPTS = "${common.confgenFile "cgassets/constsiz_opts.json"}";

  deps = pkgs.stdenvNoCC.mkDerivation {
    name = "mzte-scripts-packages";
    src = ./..;

    outputHashMode = "recursive";
    outputHash = "sha256-v092gVzym6Tuozvj7IqQSl5zcto/Z2lmg/bXWApYd0M=";
    preferLocalBuild = true;

    nativeBuildInputs = with pkgs; [
      zig_0_13
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
      xorg.libxcb # used in some old code in randomwallpaper, should probably be yoinked
    ];

    env = { inherit CGOPTS; };

    postPatch = ''
      ln -sf "${deps}" "$ZIG_GLOBAL_CACHE_DIR/p"
    '';
  };
}
