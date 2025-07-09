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
        rev = "dd7a69308a0906a681c210b09a1c3a02a862a7b1";
        hash = "sha256-nzJ7wY0USJdEg7hOYTjpcoWKIFYGo5akRNorWnHTiKg=";
      };

      useFetchCargoVendor = true;
      cargoHash = "sha256-JrtLJa/DClktK5ih0H0ofRV8CzQaK78P5Rm9Tsgrzc4=";

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
