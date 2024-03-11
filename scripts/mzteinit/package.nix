{ pkgs, lib }:
{ setEnvironment ? null }:
pkgs.writeShellApplication {
  name = "mzteinit";

  # We need a wrapper script here because nix cannot build mzteinit while taking localconf into
  # account, as the builder has no access to the home directory. Thus, the user must build
  # mzteinit and we need to launch it here (before it's contained in $PATH, hence the absolute path).
  text = ''
    ${lib.optionalString (setEnvironment != null) ''
    if [ -z "$__NIXOS_SET_ENVIRONMENT_DONE" ]; then
      # shellcheck disable=SC1091
      . ${setEnvironment}
    fi
    '' }
    mzteinit_path="$HOME"/.local/bin/mzteinit
    if [[ -f "$mzteinit_path" ]]; then
      exec $mzteinit_path
    else
      echo "mzteinit not found, starting pre-launch emergency shell!"
      exec ${pkgs.bash}/bin/bash
    fi
  '';

  bashOptions = [ "errexit" "pipefail" ];

  derivationArgs.passthru.shellPath = "/bin/mzteinit";
}
