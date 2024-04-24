{ lib, pkgs, config, ... }:
let
  flakePkg = ref: (builtins.getFlake ref).packages.${pkgs.system}.default;
in
{
  options.mzte-nix-packages = lib.mkOption { };

  config.mzte-nix-packages = [
    pkgs.nix-output-monitor
    pkgs.nix-du
    (flakePkg "github:nix-community/zon2nix")
  ];

  config.packages.mzte-nix = pkgs.symlinkJoin {
    name = "mzte-nix";
    paths = config.mzte-nix-packages;
  };
}
