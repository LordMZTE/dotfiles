{ common, lib, pkgs, config, ... }:
let
  flakePkg = ref: (builtins.getFlake ref).packages.${pkgs.system}.default;
in
{
  options.mzte-nix-packfuncs = lib.mkOption { };

  config.nixpkgs.overlays = [
    #(final: prev: { })
  ];

  config.mzte-nix-packfuncs = [ ];

  config.output.packfuncs.mzte-nix = { pkgs, ... }: pkgs.symlinkJoin {
    name = "mzte-nix";
    paths = lib.concatMap
      (pf: let p = pkgs.callPackage pf { }; in map (o: p.${o}) p.outputs)
      config.mzte-nix-packfuncs;
  };
}
