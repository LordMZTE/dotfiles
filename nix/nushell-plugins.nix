{ config, lib, pkgs, ... }:
{
  options.nushell-plugins = lib.mkOption { };

  config.nushell-plugins = {
    jobcontrol = (builtins.getFlake
      "git+https://git.mzte.de/LordMZTE/nu-plugin-jobcontrol.git?rev=3a02910ff138691ecf3557722411e53261d900d4"
    ).outputs.packages.${pkgs.system}.default;

    dbus = (pkgs.rustPlatform.buildRustPackage rec {
      name = "nu-plugin-dbus";
      version = "0.13.0";
      #src = pkgs.fetchCrate {
      #  inherit version;
      #  pname = "nu_plugin_dbus";
      #  hash = "sha256-UBpqgw6qqcEDW5bbSWJ/aaSSbEG5B/D6nvcbokX8aeA=";
      #};
      src = pkgs.fetchFromGitHub {
        owner = "LordMZTE";
        repo = "nu_plugin_dbus";
        rev = "a682d442cef12a84553c5fcd56c8f10f2cbda0e6";
        hash = "sha256-BazLyxZ7h3C+8llr0SkdM5+o9HiDXHZMtIPJjY05n4E=";
      };

      cargoHash = "sha256-DxcOLycX4kjff+XgParpGjio+MxpEA5t0+9x7XHrKgU=";

      nativeBuildInputs = with pkgs; [ pkg-config ];
      buildInputs = with pkgs; [ dbus ];
    });
    inherit (pkgs.nushellPlugins) polars formats query;
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
