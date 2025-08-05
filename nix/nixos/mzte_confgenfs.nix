{ lib, pkgs, config, ... }:
let conf = config.services.mzte_confgenfs; in
{
  options.services.mzte_confgenfs = {
    enable = lib.mkEnableOption "ConfgenFS";

    package = lib.mkPackageOption pkgs "confgen" { };

    mountpoint_rel = lib.mkOption {
      type = lib.types.str;
      description = "Mountpoint appended to the user home directory.";
      default = "confgenfs";
    };

    confgenfile_rel = lib.mkOption {
      type = lib.types.str;
      description = "Confgenfile appended to the user home directory.";
      default = "dev/dotfiles/confgen.lua";
    };
  };

  config = lib.mkIf conf.enable {
    systemd.user.services.confgenfs = {
      wantedBy = [ "default.target" ];
      serviceConfig.ExecStart = pkgs.writeCBin "start-confgenfs" ''
        #include <stdlib.h>
        #include <stdbool.h>
        #include <string.h>
        #include <unistd.h>

        int main() {
          const char *home = getenv("HOME"), *path = getenv("PATH");

          // Lua libraries required by dotfiles.
          setenv("LUA_CPATH", "${pkgs.luajitPackages.luafilesystem}/lib/lua/5.1/?.so", true);

          char* newpath = malloc(strlen(path) + 64);
          newpath[0] = 0;
          strcat(newpath, "/run/current-system/sw/bin:");
          strcat(newpath, path);
          setenv("PATH", newpath, true);
          free(newpath);

          char cgfile[1024] = {0}, mountpoint[1024] = {0};

          strcat(cgfile, home);
          strcat(cgfile, "/${conf.confgenfile_rel}");

          strcat(mountpoint, home);
          strcat(mountpoint, "/${conf.mountpoint_rel}");

          const char *cgfs_bin = "${toString conf.package}/bin/confgenfs";
          return execl(
            cgfs_bin,
            cgfs_bin,
            cgfile,
            mountpoint,
            NULL
          );
        }
      '' + "/bin/start-confgenfs";

    };
  };
}
