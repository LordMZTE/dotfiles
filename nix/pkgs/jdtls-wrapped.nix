# A wrapper around jdtls that provides the correct Java version

{ ... }:
{
  output.packfuncs.jdtls-wrapped = { pkgs, ... }: pkgs.writeShellScriptBin "jdtls" ''
    export PATH="$PATH:${pkgs.jre17_minimal}/bin"
    export JAVA_HOME="${pkgs.jre17_minimal}"

    exec "${pkgs.jdt-language-server}/bin/jdtls" "$@"
  '';
}
