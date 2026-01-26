{ ... }:
{
  output.packfuncs = {
    rofi-qalc = import ./rofi-qalc.nix;
    xarchiver-tap = import ./xarchiver-tap;
  };

  imports = [
    ./jdtls-wrapped.nix
    ./thumbnailers.nix
  ];
}
