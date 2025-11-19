{ pkgs, lib, ... }:
let
  plugin = url: fetchGit { inherit url; };
  plugins = {
    "udisks" = (builtins.getFlake
      "git+https://git.mzte.de/LordMZTE/udisks.xplr").packages.${pkgs.stdenv.targetPlatform.system}.default + "/udisks";
    "dragon" = plugin "https://github.com/sayanarijit/dragon.xplr";
    "zoxide" = plugin "https://github.com/sayanarijit/zoxide.xplr";
    "web-devicons" = plugin "https://gitlab.com/hartan/web-devicons.xplr";
  };
in
{
  cgnix.entries.xplr_plugins = pkgs.linkFarm "xplr-plugins" (lib.mapAttrsToList
    (k: v: {
      name = k;
      path = v;
    })
    plugins);
}
