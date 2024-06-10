{ config, lib, pkgs, ... }:
{
  options.nushell-plugins = lib.mkOption { };

  config.nushell-plugins = [
    (pkgs.rustPlatform.buildRustPackage {
      name = "nu-plugin-dbus";
      src = pkgs.fetchCrate {
        pname = "nu_plugin_dbus";
        version = "0.7.0";
        hash = "sha256-Xw8/8ROem+9fTRwFxr4p1ZKFVdRnsUwFhmyu87OylKY=";
      };

      cargoSha256 = "sha256-Rg6YCPUPib2U9FHHgKrTPyyWblj9QEbiKmQom3MpXPU=";

      nativeBuildInputs = with pkgs; [ pkg-config ];
      buildInputs = with pkgs; [ dbus ];
    })
    (pkgs.rustPlatform.buildRustPackage {
      name = "nu-plugin-formats";
      src = pkgs.fetchCrate {
        pname = "nu_plugin_formats";
        version = "0.94.2";
        hash = "sha256-MqE6iD8MjavdSIxGZFGtuuzjZFcwtW7upFBlwOR08+o=";
      };

      cargoSha256 = "sha256-7EBD4WtKHRX+34fao3oXOlb1UPpejxEL6Vagy9iH92I=";
    })
    (pkgs.rustPlatform.buildRustPackage {
      name = "nu-plugin-polars";
      src = pkgs.fetchCrate {
        pname = "nu_plugin_polars";
        version = "0.94.2";
        hash = "sha256-rSwJImUi9k+MLPKaBxgV8UU1gTWoxCJHAtkUtYVvbyA=";
      };

      cargoSha256 = "sha256-llJGgqaoM1fJ9bdA0ohlf/TQqYOWjrl1RoONgSeTDHo=";

      doCheck = false; # Needs OpenSSL, which build doesn't for some reason.
    })
  ];

  config.packages.nushell-plugins =
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
