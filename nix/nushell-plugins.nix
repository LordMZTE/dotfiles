{ config, lib, pkgs, ... }:
let
  nu-ver = "0.95.0";
in 
{
  options.nushell-plugins = lib.mkOption { };

  config.nushell-plugins = [
    (pkgs.rustPlatform.buildRustPackage rec {
      name = "nu-plugin-dbus";
      version = "0.8.0";
      src = pkgs.fetchCrate {
        inherit version;
        pname = "nu_plugin_dbus";
        hash = "sha256-Ogc4iw0LIDoxyQnoTXzbNaQ6jHtkjmWja/a3TB1TZjk=";
      };

      cargoSha256 = "sha256-Q7ASOcS/d2YM02kaIwRzIegGcESU3mr/qRpxwv4KGHo=";

      nativeBuildInputs = with pkgs; [ pkg-config ];
      buildInputs = with pkgs; [ dbus ];
    })
    (pkgs.rustPlatform.buildRustPackage rec {
      name = "nu-plugin-formats";
      version = nu-ver;
      src = pkgs.fetchCrate {
        inherit version;
        pname = "nu_plugin_formats";
        hash = "sha256-nwfLQxVzzUfBn7m1F669NThqzG9bAXlM/lCAVGDKY8o=";
      };

      cargoSha256 = "sha256-e8VcSJYH5P4LR1bFbmeiiF+fSfRlqTEzfnkPtUFmB2I=";
    })
    (pkgs.rustPlatform.buildRustPackage rec {
      name = "nu-plugin-polars";
      version = nu-ver;
      src = pkgs.fetchCrate {
        inherit version;
        pname = "nu_plugin_polars";
        hash = "sha256-d2giFOByeX/lLc6k3e4cf/RodwV2yLjqeZD+cmVIwK8=";
      };

      cargoSha256 = "sha256-e0r693pJJM3IjKjjwxvoIUi3y6avUI9m2qQ9rpSAtLU=";

      doCheck = false; # Needs OpenSSL, which build doesn't for some reason.
    })
    (pkgs.rustPlatform.buildRustPackage rec {
      name = "nu-plugin-query";
      version = nu-ver;
      src = pkgs.fetchCrate {
        inherit version;
        pname = "nu_plugin_query";
        hash = "sha256-3lWBqP3ZeHsQApvZmvAsVgseZWrIPDfgm+lZxkDO1JE=";
      };

      cargoSha256 = "sha256-BOAzv7N9UfIxIA0YGYLc/DfU5VSowYtxe6UYZjQ/rf4=";
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
