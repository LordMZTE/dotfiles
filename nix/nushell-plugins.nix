{ config, lib, pkgs, ... }:
{
  options.nushell-plugins = lib.mkOption { };

  config.nushell-plugins = {
    # This is technically in nixpkgs, but the version there is the outdated upstream.
    dbus = pkgs.rustPlatform.buildRustPackage {
      name = "nu_plugin_dbus";

      src = pkgs.fetchFromGitHub {
        owner = "LordMZTE";
        repo = "nu_plugin_dbus";
        rev = "ed3a2b5f15d015b8497f3957f854b22f1dfa186e";
        hash = "sha256-dwlZbCbsCm5f2vFHVNfDae0/Ms7WCgL7Z83CC9W19Ks=";
      };

      cargoHash = "sha256-ncKjbfRoSU+YBMZ9PKllj0q/VmdV146eWhu6/8sr3lA=";

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
