{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , utils
    }: utils.lib.eachDefaultSystem
      (system:
      let
        pkgs = import nixpkgs { inherit system; };
        common = pkgs.callPackage ./lib/common-nix { };
        flakePkg = ref: (builtins.getFlake ref).packages.${system}.default;

        root-mod = {
          options.packages = nixpkgs.lib.mkOption { };
          options.dev-shells = nixpkgs.lib.mkOption { };

          config._module.args = {
            inherit pkgs system;
            inherit (pkgs) lib stdenv;
          };

          # Local user nix env
          config.packages.mzte-nix = pkgs.symlinkJoin {
            name = "mzte-nix";
            paths = [
              pkgs.nix-output-monitor
              pkgs.nix-du
              (flakePkg "github:nix-community/zon2nix")
            ];
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
        mzteinit = pkgs.callPackage ./scripts/mzteinit/package.nix { };
        packages = modopt.config.packages;
        devShells = modopt.config.dev-shells;
      });
}
