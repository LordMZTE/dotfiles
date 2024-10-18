{ config, lib, pkgs, ... }:
let
  nu-ver = "0.99.0";
in
{
  options.nushell-plugins = lib.mkOption { };

  config.nushell-plugins = [
    (builtins.getFlake
      "git+https://git.mzte.de/LordMZTE/nu-plugin-jobcontrol.git?rev=6233ae712a945233389a440eecc612b94e2a16d5"
    ).outputs.packages.${pkgs.system}.default

    (pkgs.rustPlatform.buildRustPackage rec {
      name = "nu-plugin-dbus";
      version = "0.12.0";
      src = pkgs.fetchCrate {
        inherit version;
        pname = "nu_plugin_dbus";
        hash = "sha256-UBpqgw6qqcEDW5bbSWJ/aaSSbEG5B/D6nvcbokX8aeA=";
      };

      cargoHash = "sha256-OrrqvHyhGq8oFmU71/r7AerZhbhZKZBrtSeT3ckKujo=";

      nativeBuildInputs = with pkgs; [ pkg-config ];
      buildInputs = with pkgs; [ dbus ];
    })
    (pkgs.rustPlatform.buildRustPackage rec {
      name = "nu-plugin-formats";
      version = nu-ver;
      src = pkgs.fetchCrate {
        inherit version;
        pname = "nu_plugin_formats";
        hash = "sha256-ccOTLeisxz24ixTULhkbXhbnlcmPTarYl+zevh3/smc=";
      };

      cargoHash = "sha256-iyAYHVO/JxGGbcD4LnDiI9B7yUfv+mVRpsJs6HUW4DY=";
    })
    (pkgs.rustPlatform.buildRustPackage rec {
      name = "nu-plugin-polars";
      version = nu-ver;
      src = pkgs.fetchCrate {
        inherit version;
        pname = "nu_plugin_polars";
        hash = "sha256-Um3buNPk/NmW1oXxo34101nJ061C2eyr/Ia/i5wvI2c=";
      };

      cargoHash = "sha256-wDElrCzkCN8yNA0amGK7iqm+yVbJ0RkgwkFxw+ExveM=";

      doCheck = false; # Needs OpenSSL, which build doesn't for some reason.
    })
    (pkgs.rustPlatform.buildRustPackage rec {
      name = "nu-plugin-query";
      version = nu-ver;
      src = pkgs.fetchCrate {
        inherit version;
        pname = "nu_plugin_query";
        hash = "sha256-tvEdpSdqTVHHi3FCp7CLij8wmxBwPZ7CMMgAimVx/s4=";
      };

      cargoHash = "sha256-4MDWMBJVOnFj7t35MrNo+YtOLEb1fjTY5FUGI3pRzeA=";

      nativeBuildInputs = with pkgs; [ pkg-config ];
      buildInputs = with pkgs; [ openssl ];
    })
  ];

  config.output.packages.nushell-plugins = pkgs.writeTextFile {
    name = "add-plugins.nu";
    text = builtins.concatStringsSep "\n"
      (map
        (d:
          ''
            plugin add ${lib.getBin d}/bin/${builtins.replaceStrings ["-"] ["_"] d.name}
          '')
        config.nushell-plugins);
  };
}
