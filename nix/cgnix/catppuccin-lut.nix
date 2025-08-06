{ pkgs, ... }:
let
  png_lut = pkgs.runCommand "catppuccin-mocha.png" { } ''
    ${pkgs.lutgen}/bin/lutgen generate \
      --palette catppuccin-mocha \
      --output $out
  '';
  lut_convert = with pkgs.python3Packages; buildPythonPackage {
    src = pkgs.fetchFromGitHub {
      owner = "mikeboers";
      repo = "LUT-Convert";
      rev = "5ee067e9dbe515afac2d385eff61278bf7ead652";
      hash = "sha256-LTfd3PZWAdhisYP5gIZOEQtQCre7Z8LRYZycGukKRu8=";
    };

    propagatedBuildInputs = [ pillow ];
  };
in
{
  cgnix.entries.catpuccin_lut = pkgs.runCommand "catppuccin-mocha.cube" { } ''
    ${lut_convert}/bin/hald_to_cube "${png_lut}" $out
  '';
}
