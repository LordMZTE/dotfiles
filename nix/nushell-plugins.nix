{ config, lib, pkgs, ... }:
{
  options.nushell-plugins = lib.mkOption { };

  config.nushell-plugins = [
    (pkgs.rustPlatform.buildRustPackage {
      name = "nu-plugin-dbus";
      src = pkgs.fetchCrate {
        pname = "nu_plugin_dbus";
        version = "0.8.0";
        hash = "sha256-Ogc4iw0LIDoxyQnoTXzbNaQ6jHtkjmWja/a3TB1TZjk=";
      };

      cargoSha256 = "sha256-Q7ASOcS/d2YM02kaIwRzIegGcESU3mr/qRpxwv4KGHo=";

      nativeBuildInputs = with pkgs; [ pkg-config ];
      buildInputs = with pkgs; [ dbus ];
    })
    (pkgs.rustPlatform.buildRustPackage {
      name = "nu-plugin-formats";
      src = pkgs.fetchCrate {
        pname = "nu_plugin_formats";
        version = "0.95.0";
        hash = "sha256-nwfLQxVzzUfBn7m1F669NThqzG9bAXlM/lCAVGDKY8o=";
      };

      cargoSha256 = "sha256-e8VcSJYH5P4LR1bFbmeiiF+fSfRlqTEzfnkPtUFmB2I=";
    })
    (pkgs.rustPlatform.buildRustPackage {
      name = "nu-plugin-polars";
      src = pkgs.fetchCrate {
        pname = "nu_plugin_polars";
        version = "0.95.0";
        hash = "sha256-d2giFOByeX/lLc6k3e4cf/RodwV2yLjqeZD+cmVIwK8=";
      };

      cargoSha256 = "sha256-e0r693pJJM3IjKjjwxvoIUi3y6avUI9m2qQ9rpSAtLU=";

      doCheck = false; # Needs OpenSSL, which build doesn't for some reason.
    })
  ];

  config.output.packages.nushell-plugins =
    let
      pluginName = d: lib.removePrefix "nu-plugin-" d.name;
    in
    pkgs.writeTextFile {
      name = "add-plugins.nu";
      text = builtins.concatStringsSep "\n"
        (map
          (d:
            ''
              if (plugin list | any { |p| $p.name == "${pluginName d}" }) { plugin rm ${pluginName d} }
              plugin add ${lib.getBin d}/bin/${builtins.replaceStrings ["-"] ["_"] d.name}
            '')
          config.nushell-plugins);
    };
}
