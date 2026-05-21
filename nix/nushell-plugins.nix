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
        rev = "3c9a9b7f0ee5655afefb663b0e74956690f8213e";
        hash = "sha256-pU445alEz7iTXqHkmF8hwLFEaI/pr/fvqMmr61paPCI=";
      };

      cargoHash = "sha256-C/fuxQgxiuySGvYOPRSKyXvJP6RCFTPG8seqWjjT8fs=";

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
