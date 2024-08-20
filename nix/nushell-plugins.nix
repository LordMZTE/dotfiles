{ config, lib, pkgs, ... }:
let
  nu-ver = "0.96.0";
in
{
  options.nushell-plugins = lib.mkOption { };

  config.nushell-plugins = [
    (builtins.getFlake
      "git+https://git.mzte.de/LordMZTE/nu-plugin-jobcontrol.git?rev=852ce5e15c4fb3e45cd9fdd36afcce0df293b92b"
    ).outputs.packages.${pkgs.system}.default

    (pkgs.rustPlatform.buildRustPackage rec {
      name = "nu-plugin-dbus";
      version = "0.9.0";
      src = pkgs.fetchCrate {
        inherit version;
        pname = "nu_plugin_dbus";
        hash = "sha256-tIXwOuKAUhtFujChNtDHu8GnO+l+HbXiVZn5Ui7K4UE=";
      };

      cargoHash = "sha256-IDKTztcdBS4pMj/x85sEvvpe68RppnioJssQsRpDpp0=";

      nativeBuildInputs = with pkgs; [ pkg-config ];
      buildInputs = with pkgs; [ dbus ];
    })
    (pkgs.rustPlatform.buildRustPackage rec {
      name = "nu-plugin-formats";
      version = nu-ver;
      src = pkgs.fetchCrate {
        inherit version;
        pname = "nu_plugin_formats";
        hash = "sha256-UHGSctwyDfQfzUwK4+5gSGgx3rKM/ANZ7YwhGkZ9+KY=";
      };

      cargoHash = "sha256-SU3aeX/yYLXsD8ljQ4obAzAesSaxaI6RULfQQNR1bg4=";
    })
    (pkgs.rustPlatform.buildRustPackage rec {
      name = "nu-plugin-polars";
      version = nu-ver;
      src = pkgs.fetchCrate {
        inherit version;
        pname = "nu_plugin_polars";
        hash = "sha256-G+wjEzUeiJfKfO5KdrnOATqG2MmQxFaDjN7eEPKEmgo=";
      };

      cargoHash = "sha256-LNdfMpAar2OVGlQjTJKfsSC2WuxtIshEMPmHQDjzMYE=";

      doCheck = false; # Needs OpenSSL, which build doesn't for some reason.
    })
    (pkgs.rustPlatform.buildRustPackage rec {
      name = "nu-plugin-query";
      version = nu-ver;
      src = pkgs.fetchCrate {
        inherit version;
        pname = "nu_plugin_query";
        hash = "sha256-APZC+sna64ptfxIcvXWto456Z7xuIxmzvxfCK1EbW+c=";
      };

      cargoHash = "sha256-5LACp9sF/Qc/1ORCXq34NTMZaMBThkvKsnTjR2+zCt0=";

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
