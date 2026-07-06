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
        owner = "LordMZTE";
        repo = "nu_plugin_dbus";
        rev = "1edb15f1740c411d9c24cae57f8cc4f295d762c8";
        hash = "sha256-IZBmpqfxQ53prvr5lecFJtjn0fVY4L00NJpV0nx1bP0=";
      };

      cargoHash = "sha256-WMS4zVX9LKXN7mS3aINkW5uhNKZ4bcDAAM+90+OqmcM=";

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
