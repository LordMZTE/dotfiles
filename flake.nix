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
        base-pkgs = (import nixpkgs {
          inherit system;
          config.permittedInsecurePackages = [
            # TODO: this is for haxe
            "mbedtls2-no-checks-2.28.10"
          ];
        });
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
                gtk3.dev
                libGL
                libgit2
                luajit
                luajitPackages.luafilesystem
                pkg-config
                wayland
                wayland-protocols
                wayland-scanner
                haxe
                mpv-unwrapped
                zig_0_15
              ];
          };

          config.nixpkgs.overlays = [
            (final: prev: {
              # Some test fail here. It's just a build dependency, so who cares.
              # This is currently a transitive dependency through Haxe. They've upgraded upstream,
              # but that hasn't made it to nixpkgs yet.
              mbedtls_2 = prev.mbedtls_2.overrideAttrs {
                pname = "mbedtls2-no-checks";

                doCheck = false;
                checkPhase = null;
              };
            })
          ];

          config.output.mzteinit = base-pkgs.callPackage ./scripts/mzteinit/package.nix { };

          config.output.packages = builtins.mapAttrs
            (_: f: pkgs.callPackage f { })
            config.output.packfuncs;

          # TODO: This causes infinite recursion, but copying exactly the same code to the caller
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
