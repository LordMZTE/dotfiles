{ lib }:
{
  localconf =
    let
      path = "${builtins.getEnv "HOME"}/.config/mzte_localconf/opts.nix";
    in
    lib.optional (builtins.pathExists path) (import path);

  confgenFile = path: /. + (builtins.getEnv "HOME") + "/confgenfs/${path}";
}
