{ config
, lib
, pkgs
, ...
}:
{
  imports = [
    ./jvm.nix
    ./nvim-plugins.nix
    ./nvim-tools.nix
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
        ${builtins.concatStringsSep "\n  " (lib.mapAttrsToList (k: v: ''["${k}"] = "${v}",'') config.cgnix.entries)}
      }
    '';
  };
}
