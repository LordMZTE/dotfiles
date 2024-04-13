{ lib, pkgs, system, config, ... }:
let
  flakePkg = ref: (builtins.getFlake ref).packages.${system}.default;
  default-packages = with pkgs; [
    # MISSING: glsl_analyzer, haxe_language_server, prosemd_lsp, racket_langserver, yamlls, zls
    # Language Servers
    (flakePkg "github:oxalica/nil")
    (pkgs.linkFarm "clang-nvim" (map
      (bin: { name = "bin/${bin}"; path = "${clang-tools}/bin/${bin}"; })
      [ "clangd" "clang-format" ])) # Don't include everything from clang-tools
    elixir-ls
    jdt-language-server
    lua-language-server
    ocamlPackages.ocaml-lsp
    openscad-lsp
    taplo
    vscode-langservers-extracted # cssls, eslint, html, jsonls

    # Formatters
    (pkgs.linkFarm "prettier" [{ name = "bin/prettier"; path = "${nodePackages.prettier}/bin/prettier"; }]) # needed due to symlink shenanigans
    fnlfmt
    nixpkgs-fmt

    # Misc
    html-tidy
    shellcheck
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
