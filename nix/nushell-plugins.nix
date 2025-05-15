{ config, lib, pkgs, ... }:
{
  options.nushell-plugins = lib.mkOption { };

  config.nushell-plugins = {
    dbus = pkgs.rustPlatform.buildRustPackage {
      name = "nu_plugin_dbus";

      src = pkgs.fetchFromGitHub {
        owner = "LordMZTE";
        repo = "nu_plugin_dbus";
        rev = "a22eac85b996f2ad0d63f9f2d4bb89fa71862260";
        hash = "sha256-PDV69TNIfcE0WH7IqQ3XXE8+JA1nsjfU/MRp8JjgNho=";
      };

      useFetchCargoVendor = true;
      cargoHash = "sha256-JR2FGB8dta5IH+O/8OJ90pSWIH8II/HgV/N7KHt7i08=";

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
