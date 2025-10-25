{ ... }:
{
  output.packfuncs.rofi-qalc = import ./rofi-qalc.nix;

  imports = [
    ./jdtls-wrapped.nix
    ./thumbnailers.nix
  ];
}
