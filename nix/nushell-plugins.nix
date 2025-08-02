{ config, lib, pkgs, ... }:
{
  options.nushell-plugins = lib.mkOption { };

  config.nushell-plugins = {
    # This is technically in nixpkgs, but the version there is the outdated upstream.
    # Thankfully, it seems like someone has since taken over my duty of creating never-to-be-merged
    # update PRs.
    dbus = pkgs.rustPlatform.buildRustPackage {
      name = "nu_plugin_dbus";

      src = pkgs.fetchFromGitHub {
        owner = "dtomvan";
        repo = "nu_plugin_dbus";
        rev = "e3bad1f97d752a368c28e656e69a79633a543be2";
        hash = "sha256-VdX9tZ0D0XNoK8gVAGUXlWb3HdzqlWYdeM/usi588RQ=";
      };

      useFetchCargoVendor = true;
      cargoHash = "sha256-GYJf3OnNEUiSVbooxCQhKjH0dXbHb3pCxFWWCOBaKBY=";

      nativeBuildInputs = with pkgs; [ pkg-config ];
      buildInputs = with pkgs; [ dbus ];
    };

    inherit (pkgs.nushellPlugins) polars formats query skim;
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
