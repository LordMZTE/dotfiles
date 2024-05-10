{ common, lib, pkgs, config, ... }:
let
  flakePkg = ref: (builtins.getFlake ref).packages.${pkgs.system}.default;
in
{
  options.mzte-nix-packages = lib.mkOption { };

  config.nixpkgs.overlays = [
    (final: prev: {
      nsxiv = prev.nsxiv.overrideAttrs {
        patches = [ (common.confgenFile "cgassets/nix/nsxiv-config.patch") ];
      };
      nsxiv-pipe = prev.stdenvNoCC.mkDerivation {
        name = "nsxiv-pipe";
        src = prev.fetchurl {
          url = "https://codeberg.org/nsxiv/nsxiv-extra/raw/commit/7cdf1a8dba145f2aaf5734b3d084b1d56bea6554/scripts/nsxiv-pipe/nsxiv-pipe";
          hash = "sha256-fphucoQzR5gWG78xr68AkclMDF6l9BsgVOVQzjK6vrU=";
        };

        dontUnpack = true;
        dontBuild = true;
        dontFixup = true;

        installPhase = ''
          runHook preInstall
          mkdir -p $out/bin
          substitute $src $out/bin/nsxiv-pipe \
            --replace "nsxiv " "${final.nsxiv}/bin/nsxiv "
          chmod +x $out/bin/nsxiv-pipe
          patchShebangs $out/bin/nsxiv-pipe
          runHook postInstall
        '';
      };
    })
  ];

  config.mzte-nix-packages = with pkgs; [
    nix-output-monitor
    nix-du
    nsxiv
    nsxiv-pipe
    (flakePkg "github:nix-community/zon2nix")
  ];

  config.packages.mzte-nix = pkgs.symlinkJoin {
    name = "mzte-nix";
    paths = lib.concatMap (p: map (o: p.${o}) p.outputs) config.mzte-nix-packages;
  };
}
