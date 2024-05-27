{ config, lib, pkgs, ... }:
{
  options.nushell-plugins = lib.mkOption { };

  config.nushell-plugins = [
    (pkgs.rustPlatform.buildRustPackage {
      name = "nu-plugin-dbus";
      src = pkgs.fetchCrate {
        pname = "nu_plugin_dbus";
        version = "0.6.1";
        hash = "sha256-AqAtTpJWH0s3t7PrRXlgIHXwkaWsoFlOIouaiUaIQKg=";
      };

      cargoSha256 = "sha256-goDlrTU1XZVRQ8xvonY07n0FPZgheBm9y7chsZ3ZTKQ=";

      nativeBuildInputs = with pkgs; [ pkg-config ];
      buildInputs = with pkgs; [ dbus ];
    })
    (pkgs.rustPlatform.buildRustPackage {
      name = "nu-plugin-formats";
      src = pkgs.fetchCrate {
        pname = "nu_plugin_formats";
        version = "0.93.0";
        hash = "sha256-1nvSPH+1wdEDlSXf/nW2+A3S/VaumhFucM5zCXIgh58=";
      };

      cargoSha256 = "sha256-RjYeJFPCttUs1kUkiuWzIhBl6pfZmsKJNvsH8w3+r6A=";
    })
    (pkgs.rustPlatform.buildRustPackage {
      name = "nu-plugin-polars";
      src = pkgs.fetchCrate {
        pname = "nu_plugin_polars";
        version = "0.93.0";
        hash = "sha256-6Cjfa4vDex2XYE8PGV80P/ciMBcDN1gkA8vl5X7Lux0=";
      };

      cargoSha256 = "sha256-ziXLe2kdk4CSeE9M4m86PMvXcwJLgjypYEWcfw+yTg0=";

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
