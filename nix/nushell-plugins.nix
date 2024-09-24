{ config, lib, pkgs, ... }:
let
  nu-ver = "0.98.0";
in
{
  options.nushell-plugins = lib.mkOption { };

  config.nushell-plugins = [
    (builtins.getFlake
      "git+https://git.mzte.de/LordMZTE/nu-plugin-jobcontrol.git?rev=40127dfa0573e0cc6c273d291f5423aa5964d76a"
    ).outputs.packages.${pkgs.system}.default

    (pkgs.rustPlatform.buildRustPackage rec {
      name = "nu-plugin-dbus";
      version = "0.11.0";
      #src = pkgs.fetchCrate {
      #  inherit version;
      #  pname = "nu_plugin_dbus";
      #  hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
      #};
      src = pkgs.fetchFromGitHub {
        # Updated Fork
        owner = "Canvis-Me";
        repo = "nu_plugin_dbus";
        rev = "a0f8eb54355e4fbf121f5f8a0a7e7d67b07e33bd";
        hash = "sha256-CrTVLbD7Q/swDCxiWcqoxkB8X6ydfxhTAZjoT0SoB4I=";
      };

      cargoHash = "sha256-zyoZc+ItEiWMBeu8Ulbn2lAzFH2DeBbP7Rs+QLsBo+Y=";

      nativeBuildInputs = with pkgs; [ pkg-config ];
      buildInputs = with pkgs; [ dbus ];
    })
    (pkgs.rustPlatform.buildRustPackage rec {
      name = "nu-plugin-formats";
      version = nu-ver;
      src = pkgs.fetchCrate {
        inherit version;
        pname = "nu_plugin_formats";
        hash = "sha256-/RJLHFlgKbshNeEF8YHdthZWTnJ8p1M2Xb1AJ44VvGs=";
      };

      cargoHash = "sha256-FIqE8u8RBVhGUvssRGLhH7kNvEfQFkYLDujTVT4liNA=";
    })
    (pkgs.rustPlatform.buildRustPackage rec {
      name = "nu-plugin-polars";
      version = nu-ver;
      src = pkgs.fetchCrate {
        inherit version;
        pname = "nu_plugin_polars";
        hash = "sha256-qG7popu37L60+N0C6ayvvQKVfDaZiE5G9JXTK4unY/w=";
      };

      cargoHash = "sha256-TvE5qJl+TQRhk0Q08zO37bLoJkVpQ5i0DAcnGwzNWzM=";

      doCheck = false; # Needs OpenSSL, which build doesn't for some reason.
    })
    (pkgs.rustPlatform.buildRustPackage rec {
      name = "nu-plugin-query";
      version = nu-ver;
      src = pkgs.fetchCrate {
        inherit version;
        pname = "nu_plugin_query";
        hash = "sha256-ZY/rrahYg1gYjq1qsaQ34JQXd0PzWt3h5XqCMFaoanE=";
      };

      cargoHash = "sha256-ieFwg/Y/FuO2Rq6cjc6eyskV8/MzBWJVaFSGdwb53qA=";

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
