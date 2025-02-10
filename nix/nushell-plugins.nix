{ config, lib, pkgs, ... }:
{
  options.nushell-plugins = lib.mkOption { };

  config.nushell-plugins = {
    jobcontrol = (builtins.getFlake
      "git+https://git.mzte.de/LordMZTE/nu-plugin-jobcontrol.git?rev=4709b7677347fd7f33fadc202278547f4ada0629"
    ).outputs.packages.${pkgs.system}.default;

    dbus = pkgs.rustPlatform.buildRustPackage {
      name = "nu_plugin_dbus";

      src = pkgs.fetchFromGitHub {
        owner = "LordMZTE";
        repo = "nu_plugin_dbus";
        rev = "dafedb90a487c7d1cc158bf3b4ffcee5e19d595d";
        hash = "sha256-oxaz3/C/ifgZRVsAY0/ZuzpgYQ8XBREzvbmJCyCVuzE=";
      };

      useFetchCargoVendor = true;
      cargoHash = "sha256-ZVaX6DcswyblpYXIjuOF8CBdMWr3HAhxw/St9EAMPss=";

      nativeBuildInputs = with pkgs; [ pkg-config ];
      buildInputs = with pkgs; [ dbus ];
    };

    inherit (pkgs.nushellPlugins) polars formats query;
  };

  config.output.packages.nushell-plugins = pkgs.writeTextFile {
    name = "add-plugins.nu";
    text = builtins.concatStringsSep "\n"
      (lib.mapAttrsToList
        (name: d:
          ''
            plugin add ${lib.getBin d}/bin/nu_plugin_${name}
          '')
        config.nushell-plugins);
  };
}
