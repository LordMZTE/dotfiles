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
        pkgs = import nixpkgs { inherit system; };
        common = pkgs.callPackage ./lib/common-nix { };

        root-mod = {
          options.packages = nixpkgs.lib.mkOption { };
          options.dev-shells = nixpkgs.lib.mkOption { };

          config._module.args = {
            inherit inputs;
            inherit pkgs system;
            inherit (pkgs) lib stdenv stdenvNoCC;
          };

          # devshell for the dotfiles
          config.dev-shells.default = nixpkgs.legacyPackages.${system}.mkShell {
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
        };

        modopt = nixpkgs.lib.evalModules {
          modules = [ root-mod ./nix ] ++ common.localconf;
          specialArgs = { inherit common; };
        };
      in
      {
        config = modopt;
        mzteinit = pkgs.callPackage ./scripts/mzteinit/package.nix { };
        packages = modopt.config.packages;
        devShells = modopt.config.dev-shells;
      });
}
