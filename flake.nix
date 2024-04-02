{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , utils
    }: utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
      flakePkg = ref: (builtins.getFlake ref).packages.${system}.default;
    in
    {
      mzteinit = pkgs.callPackage ./scripts/mzteinit/package.nix { };
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

      devShells.default = nixpkgs.legacyPackages.${system}.mkShell {
        buildInputs = with pkgs; [
          # packages required to build scripts
          libGL
          libgit2
          luajit
          pkg-config
          racket
          roswell
          wayland
          wayland-protocols
          haxe
          mpv-unwrapped
        ] ++
        # shorthands for setup.rkt
        builtins.map
          (cmd: pkgs.writeShellScriptBin cmd ''
            ./setup.rkt ${cmd}
          '') [
          "install-scripts"
          "install-plugins"
          "install-lsps-paru"
          "setup-nvim-config"
          "setup-nix"
          "run-confgen"
        ];
      };
    });
}
