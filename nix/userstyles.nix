# Module that provides an output for a stylus import file with catppuccin themes.
{ pkgs, stdenvNoCC, ... }:
let
  flavor = "mocha";
  accent-color = "red";
in 
{
  packages.userstyles = stdenvNoCC.mkDerivation {
    name = "userstyles.json";
    src = pkgs.fetchurl {
      url = "https://github.com/catppuccin/userstyles/releases/download/all-userstyles-export/import.json";
      hash = "sha256-eYU9Y95au9mI3muS4+1QJt31W7s2zVmurdKbQ1dU+pk=";
    };

    dontUnpack = true;

    # TODO: use better language
    realBuilder = "${pkgs.deno}/bin/deno";
    args = [
      "run"
      "-A"
      (pkgs.writeText "build.js" ''
        const json = await import(Deno.env.get("src"), { with: { type: "json" } });
        const processed = json.default.map(theme => {
          if (theme.usercssData?.vars?.accentColor?.default)
            theme.usercssData.vars.accentColor.default = "${accent-color}";

          if (theme.usercssData?.vars?.darkFlavor?.default)
            theme.usercssData.vars.darkFlavor.default = "${flavor}";

            return theme;
        });

        Deno.writeTextFileSync(Deno.env.get("out"), JSON.stringify(processed));
      '')
    ];
  };
}
