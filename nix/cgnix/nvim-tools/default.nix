{ lib, pkgs, system, config, ... }:
let
  flakePkg = ref: (builtins.getFlake ref).packages.${system}.default;
  default-packages = with pkgs; [
    # MISSING: racket_langserver
    # Language Servers
    (pkgs.linkFarm "clang-nvim" (map
      (bin: { name = "bin/${bin}"; path = "${clang-tools}/bin/${bin}"; })
      [ "clangd" "clang-format" ])) # Don't include everything from clang-tools
    (pkgs.stdenv.mkDerivation {
      name = "glsl-analyzer";
      src = pkgs.fetchFromGitHub {
        owner = "nolanderc";
        repo = "glsl_analyzer";
        rev = "3514b232795858c6a1870832d2ff033eb54103ab";
        leaveDotGit = true;
        hash = "sha256-2+Q9A6QXbMuwlHRK2d1xxK3OBzk/I/cw96H6o4YnVKc=";
      };

      dontConfigure = true;

      nativeBuildInputs = with pkgs; [ zig_0_12.hook git ];
    })
    (flakePkg "git+https://git.mzte.de/LordMZTE/haxe-language-server.git")
    config.output.packages.jdtls-wrapped
    lua-language-server
    (flakePkg "github:oxalica/nil")
    ocamlPackages.ocaml-lsp
    openscad-lsp
    (pkgs.rustPlatform.buildRustPackage {
      name = "prosemd-lsp";
      src = pkgs.fetchFromGitHub {
        owner = "kitten";
        repo = "prosemd-lsp";
        rev = "d6073d9ec269cec820b3efc77e0f62bcff47790e";
        hash = "sha256-Mkbl8wT04sNjV7fpDJh9HbEqnCdi6SMXdlPCbT2801c=";
      };

      cargoHash = "sha256-/jx1hC/98v5L8XLG3ecFkk5H60HDtaKede+a8HDeFk4=";
    })
    rust-analyzer
    taplo
    tinymist
    vscode-langservers-extracted # cssls, eslint, html, jsonls
    zls

    # Formatters
    (pkgs.linkFarm "prettier" [{ name = "bin/prettier"; path = "${nodePackages.prettier}/bin/prettier"; }]) # needed due to symlink shenanigans
    fnlfmt
    nixpkgs-fmt
    rustfmt
    shfmt
    stylua

    # Misc
    html-tidy
    shellcheck
    tree-sitter
  ];
in
{
  options.cgnix.nvim-tools = lib.mkOption {
    default = default-packages;
  };

  config.cgnix.entries.nvim_tools = pkgs.symlinkJoin {
    name = "nvim-tools";
    paths = config.cgnix.nvim-tools;
  };
}
