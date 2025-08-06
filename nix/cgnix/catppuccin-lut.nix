{ pkgs, ... }:
let
  png_lut = pkgs.runCommand "catppuccin-mocha.png" { } ''
    ${pkgs.lutgen}/bin/lutgen generate \
      --palette catppuccin-mocha \
      --preserve --lum 0.5 \
      --output $out
  '';
  lut_convert =
    let
      python = pkgs.python3.withPackages (p: [ p.pillow ]);
    in
    pkgs.stdenvNoCC.mkDerivation {
      pname = "lut-convert";
      version = "0-unstable-2013-05-23";

      src = pkgs.fetchFromGitHub {
        owner = "mikeboers";
        repo = "LUT-Convert";
        rev = "5ee067e9dbe515afac2d385eff61278bf7ead652";
        hash = "sha256-LTfd3PZWAdhisYP5gIZOEQtQCre7Z8LRYZycGukKRu8=";
      };

      doBuild = false;

      installPhase = ''
        mkdir -p $out/bin
        echo '#!${python}/bin/python3' >> $out/bin/hald_to_cube
        cat $src/hald_to_cube.py >> $out/bin/hald_to_cube
        chmod +x $out/bin/hald_to_cube
      '';
    };
in
{
  cgnix.entries.catppuccin_lut = pkgs.runCommand "catppuccin-mocha.cube" { } ''
    ${lut_convert}/bin/hald_to_cube "${png_lut}" $out
  '';
}
