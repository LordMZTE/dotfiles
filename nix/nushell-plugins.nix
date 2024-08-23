{ config, lib, pkgs, ... }:
let
  nu-ver = "0.97.1";
in
{
  options.nushell-plugins = lib.mkOption { };

  config.nushell-plugins = [
    (builtins.getFlake
      "git+https://git.mzte.de/LordMZTE/nu-plugin-jobcontrol.git?rev=e6795955c0cf8a5fe18babfe43fdc92282515532"
    ).outputs.packages.${pkgs.system}.default

    (pkgs.rustPlatform.buildRustPackage rec {
      name = "nu-plugin-dbus";
      version = "0.10.0";
      src = pkgs.fetchFromGitHub {
        owner = "LordMZTE";
        repo = "nu_plugin_dbus";
        rev = "195c5d4c447a8b64c4c1f2818af63595c1990a53";
        hash = "sha256-XVLX0tCgpf5Vfr00kbQZPWMolzHpkMVYKoBHYylpz48=";
      };
      #src = pkgs.fetchCrate {
      #  inherit version;
      #  pname = "nu_plugin_dbus";
      #  hash = "";
      #};

      cargoHash = "sha256-0i5OxunUT1K3hP9n496SCXe24lry4ModkspGlphkmBI=";

      nativeBuildInputs = with pkgs; [ pkg-config ];
      buildInputs = with pkgs; [ dbus ];
    })
    (pkgs.rustPlatform.buildRustPackage rec {
      name = "nu-plugin-formats";
      version = nu-ver;
      src = pkgs.fetchCrate {
        inherit version;
        pname = "nu_plugin_formats";
        hash = "sha256-zXyaoEGlXTW0V2W5SRhaucOGG97iWyVsf+OXIEtcQZo=";
      };

      cargoHash = "sha256-M5H8BGCKLKkfSz9qQ24qvhA81jzri/ZyWg8xs/iwri0=";
    })
    (pkgs.rustPlatform.buildRustPackage rec {
      name = "nu-plugin-polars";
      version = nu-ver;
      src = pkgs.fetchCrate {
        inherit version;
        pname = "nu_plugin_polars";
        hash = "sha256-OQsQSXesLJyrWO/c4AfTmYcviUKpZNrL1BePa6wMcwk=";
      };

      cargoHash = "sha256-cqNGI40VjqAkpU/jTwXuHrZZ3wJxiDGVQVl2HTXmYqw=";

      doCheck = false; # Needs OpenSSL, which build doesn't for some reason.
    })
    (pkgs.rustPlatform.buildRustPackage rec {
      name = "nu-plugin-query";
      version = nu-ver;
      src = pkgs.fetchCrate {
        inherit version;
        pname = "nu_plugin_query";
        hash = "sha256-6UQHxjWDp5ak4ouyru5K9VGt8JaIzArYgyJnqe5d0KA=";
      };

      cargoHash = "sha256-z2betxX5fgzPlr1+9/IZVSUyb/hjw+4C9DHYWUwoWRg=";

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
