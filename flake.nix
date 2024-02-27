{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }: utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
      flakePkg = ref: (builtins.getFlake ref).packages.${system}.default;
    in
    {
      # Local user nix env
      packages.mzte-nix = pkgs.symlinkJoin {
        name = "mzte-nix";
        paths = [
          pkgs.nixpkgs-fmt
          pkgs.nix-output-monitor
          pkgs.nix-du
          (flakePkg "github:oxalica/nil")
          (flakePkg "github:nix-community/zon2nix")
        ];
      };
    });
}
