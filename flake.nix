{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
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

          options.output = {
            packfuncs = nixpkgs.lib.mkOption {
              default = { };
              type = with nixpkgs.lib.types; attrsOf (functionTo package);
            };

            packages = nixpkgs.lib.mkOption {
              default = { };
              type = with nixpkgs.lib.types; attrsOf package;
            };

            devShells = nixpkgs.lib.mkOption {
              default = { };
              type = with nixpkgs.lib.types; attrsOf package;
            };

            mzteinit = nixpkgs.lib.mkOption {
              default = { };
              type = with nixpkgs.lib.types; anything;
            };

            overlay = nixpkgs.lib.mkOption {
              default = { };
              type = with nixpkgs.lib.types; anything;
            };
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
                ddcutil # libddcutil for brightness script
                gdk-pixbuf
                libGL
                libgit2
                luajit
                luajitPackages.luafilesystem
                pkg-config
                racket
                wayland
                wayland-protocols
                wayland-scanner
                haxe
                mpv-unwrapped
                zig_0_15
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

          config.output.packages = builtins.mapAttrs
            (_: f: pkgs.callPackage f { })
            config.output.packfuncs;

          # TODO: This causes infinite recursing, but copying exactly the same code to the caller
          # works. I call bullshit.
          #config.output.overlay = final: prev: builtins.mapAttrs
          #  (_: f: final.callPackage f { })
          #  config.output.packfuncs;
        };

        modopt = nixpkgs.lib.evalModules {
          modules = [ root-mod ./nix ] ++ common.localconf;
          specialArgs = { inherit common; };
        };
      in
      modopt.config.output // {
        config = modopt;

      }) // { nixosModules.default = ./nix/nixos; };
}
