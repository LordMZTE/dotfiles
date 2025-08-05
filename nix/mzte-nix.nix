{ common, lib, pkgs, config, ... }:
let
  flakePkg = ref: (builtins.getFlake ref).packages.${pkgs.system}.default;
in
{
  options.mzte-nix-packfuncs = lib.mkOption { };

  config.nixpkgs.overlays = [
    (final: prev: {
      nsxiv = prev.nsxiv.overrideAttrs {
        patches = [ (common.confgenFile "cgassets/nix/nsxiv-config.patch") ];
      };
      nsxiv-pipe = prev.stdenvNoCC.mkDerivation {
        name = "nsxiv-pipe";
        src = prev.fetchurl {
          url = "https://codeberg.org/nsxiv/nsxiv-extra/raw/commit/f7d1efe3495949e2e88fdfef37aed5a40400acea/scripts/nsxiv-pipe/nsxiv-pipe";
          sha256 = "sha256-q651YZlot/lEKyIqVBvvXWUTsdpUbIvg9BGH0dZ77u8=";
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

  config.mzte-nix-packfuncs = [
    ({ pkgs, ... }: pkgs.nsxiv)
    ({ pkgs, ... }: pkgs.nsxiv-pipe)
  ];

  config.output.packfuncs.mzte-nix = { pkgs, ... }: pkgs.symlinkJoin {
    name = "mzte-nix";
    paths = lib.concatMap
      (pf: let p = pkgs.callPackage pf { }; in map (o: p.${o}) p.outputs)
      config.mzte-nix-packfuncs;
  };
}
