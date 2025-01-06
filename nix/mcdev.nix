# A dev shell for Minecraft development, including necessary dependencies for the game to run.

{ pkgs, ... }:
let
  libs = with pkgs; [
    libpulseaudio
    libGL
    glfw
    openal
    stdenv.cc.cc.lib
    udev # OSHI
  ];
  xorg-libs = with pkgs.xorg; [
    libX11
    libXext
    libXcursor
    libXrandr
    libXxf86vm
  ];
in
{
  output.devShells = builtins.mapAttrs
    (_: extra-pkgs:
      let
        shpgks = libs ++ xorg-libs ++ extra-pkgs;
      in
      pkgs.mkShell {
        shellHook = ''
          export LD_LIBRARY_PATH="${pkgs.addDriverRunpath.driverLink}/lib:${pkgs.lib.makeLibraryPath shpgks}:$LD_LIBRARY_PATH"
        '';
        buildInputs = shpgks;
      })
    {
      mcdev = [ pkgs.jdk8 ];
      mcdev-new = [ pkgs.jdk17 ];
    };
}
