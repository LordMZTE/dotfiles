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
        rev = "a79772884572e5a8d11bca8d74e5ed6c2cf47848";
        leaveDotGit = true;
        hash = "sha256-9UnQ+04P3Ml69TX5OUUjun9O+4F+IE29NR09DZfVUls=";
      };

      dontConfigure = true;

      nativeBuildInputs = with pkgs; [ zig_0_14.hook git ];
    })
    (flakePkg "git+https://git.mzte.de/LordMZTE/haxe-language-server.git")
    config.output.packages.jdtls-wrapped
    ltex-ls-plus
    lua-language-server
    nixd
    openscad-lsp
    rust-analyzer
    taplo
    tinymist
    vscode-langservers-extracted # cssls, eslint, html, jsonls
    zls_0_15

    # Formatters
    (pkgs.linkFarm "prettier" [{ name = "bin/prettier"; path = "${nodePackages.prettier}/bin/prettier"; }]) # needed due to symlink shenanigans
    fnlfmt
    nixpkgs-fmt
    rustfmt
    shfmt
    stylua

    # Misc
    html-tidy
    nix-update # nix-update.nvim
    nurl # nix-update.nvim
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
