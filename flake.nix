{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , utils
    , ...
    }@inputs: utils.lib.eachDefaultSystem
      (system:
      let
        base-pkgs = (import nixpkgs { inherit system; });
        common = base-pkgs.callPackage ./lib/common-nix { };

        root-mod = { config, pkgs, ... }: {
          options.nixpkgs.overlays = nixpkgs.lib.mkOption { default = [ ]; };
          options.output = nixpkgs.lib.mkOption {
            default = { };
            type = with nixpkgs.lib.types; attrsOf anything;
          };

          config._module.args = rec {
            pkgs = base-pkgs.appendOverlays config.nixpkgs.overlays;
            inherit inputs;
            inherit system;
            inherit (pkgs) lib stdenv stdenvNoCC;
          };

          # devshell for the dotfiles
          config.output.devShells.default = nixpkgs.legacyPackages.${system}.mkShell {
            buildInputs = with pkgs;
              [
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
                zig_0_12
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

          config.output.mzteinit = base-pkgs.callPackage ./scripts/mzteinit/package.nix { };

          config.output.overlay = final: prev: config.output.packages;
        };

        modopt = nixpkgs.lib.evalModules {
          modules = [ root-mod ./nix ] ++ common.localconf;
          specialArgs = { inherit common; };
        };
      in
      modopt.config.output // {
        config = modopt;
      });
}
