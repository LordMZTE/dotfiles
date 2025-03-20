{ config, lib, pkgs, ... }:
{
  options.nushell-plugins = lib.mkOption { };

  config.nushell-plugins = {
    dbus = pkgs.rustPlatform.buildRustPackage {
      name = "nu_plugin_dbus";

      src = pkgs.fetchFromGitHub {
        owner = "LordMZTE";
        repo = "nu_plugin_dbus";
        rev = "fbf86f7b89110f7f0e8560a7575950d928617468";
        hash = "sha256-VZCQer7D/hjymbbDw8rqCoLymjCEXQAm/7d56mCnY2M=";
      };

      useFetchCargoVendor = true;
      cargoHash = "sha256-WBdr/kVSkZYlobY80loOW+g50UMmIpsdwNMJ7ceoWIE=";

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
