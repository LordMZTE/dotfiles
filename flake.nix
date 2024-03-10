{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
    confgen.url = "git+https://git.mzte.de/LordMZTE/confgen?rev=a6fbe3c79eeed1dbda04a0be501fa2b95450a03f";
    nixpkgs-zig-0-12.url = "github:vancluever/nixpkgs/vancluever-zig-0-12";
  };

  outputs =
    { self
    , nixpkgs
    , utils
    , confgen
    , nixpkgs-zig-0-12
    }: utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
      flakePkg = ref: (builtins.getFlake ref).packages.${system}.default;
    in
    {
      packages.mzteinit = import ./scripts/mzteinit/package.nix {
        inherit pkgs;
        confgen = confgen.packages.${system};
        zig_0_12 = nixpkgs-zig-0-12.legacyPackages.${system}.zig_0_12;
      };
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
          # TODO: build scripts with nix instead
          pkg-config
          wayland
          wayland-protocols
          libgit2
          libGL
          roswell
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
