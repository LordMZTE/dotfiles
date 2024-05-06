{ config
, lib
, pkgs
, ...
}:
let
  luaExpr = val: if val == null then "nil" else "[[${val}]]";
in 
{
  imports = [
    ./nvim-tools
    ./jvm.nix
    ./nvim-plugins.nix
    ./tree-sitter-parsers.nix
  ];

  options.cgnix.entries = lib.mkOption {
    default = { };
  };

  config.cgnix.entries."fennel.lua" = "${pkgs.luajitPackages.fennel}/share/lua/5.1/fennel.lua";

  config.packages.cgnix = pkgs.writeTextFile {
    name = "nix.lua";
    text = ''
      return {
        ${builtins.concatStringsSep "\n  " (lib.mapAttrsToList (k: v: ''["${k}"] = ${luaExpr v},'') config.cgnix.entries)}
      }
    '';
  };
}
