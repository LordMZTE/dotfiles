{ lib, pkgs, config, ... }:
let
  default-jvms = with pkgs; {
    java-8-openjdk = jdk8;
    java-17-openjdk = jdk17;
  };
in
{
  options.cgnix.jvms = lib.mkOption {
    default = default-jvms;
  };

  config.cgnix.entries.jvm = pkgs.linkFarm "jvm" (lib.mapAttrsToList
    (k: v: {
      name = k;
      path = "${v}/lib/openjdk";
    })
    config.cgnix.jvms);
}
