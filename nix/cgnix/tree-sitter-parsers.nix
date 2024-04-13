# This uses Nix to manage tree-sitter parsers for neovim, instead of nvim-treesitter's weird installer.
{ lib, pkgs, ... }:
let
  mapParsers = pkg:
    let
      parsername = lib.removeSuffix "-grammar" pkg.pname;
    in
    {
      # Parser
      name = "parser/${parsername}.so";
      path = "${pkg}/parser";
    };
in
{
  cgnix.entries.tree_sitter_parsers = pkgs.linkFarm
    "tree-sitter-parsers"
    (map mapParsers pkgs.vimPlugins.nvim-treesitter.allGrammars);
}

