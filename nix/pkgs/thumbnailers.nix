# A collection of tumbler-compatible thumbnailer scripts for:
# - Text
# - OpenSCAD and STL models

{ pkgs, ... }:
let
  mkThumbnailerEntry = { name, mime, exec }: pkgs.writeTextDir
    "share/thumbnailers/${name}.thumbnailer"
    ''
      [Thumbnailer Entry]
      Version=1.0
      Encoding=UTF-8
      Type=X-Thumbnailer
      Name=${name}
      MimeType=${mime}
      Exec=${exec}
    '';
in
{
  # See https://docs.xfce.org/xfce/tumbler/available_plugins#customized_thumbnailer_for_text-based_documents
  output.packages.mzte-thumbnailer-text =
    let
      textthumb = pkgs.writeShellScript "textthumb" ''
        iFile=$(<"$1")
        tempFile=$(mktemp) && {
          echo "''${iFile:0:1600}" > "$tempFile"

          ${pkgs.imagemagick}/bin/convert \
            -size 210x290 \
            -background white \
            -pointsize 5 \
            -border 10x10 \
            -bordercolor "#CCC" \
            -font ${pkgs.dejavu_fonts.minimal}/share/fonts/truetype/DejaVuSans.ttf \
            caption:@"$tempFile" \
            "$2"

          rm "$tempFile"
        }
      '';
    in
    mkThumbnailerEntry {
      name = "mzte-thumbnailer-text";
      mime = "text/plain;text/x-log;text/html;text/css;";
      exec = "${textthumb} %i %o";
    };

  output.packages.mzte-thumbnailer-openscad =
    let
      scadthumb = pkgs.writeShellScript "scadthumb" ''
        ${pkgs.openscad-unstable}/bin/openscad --imgsize "500,500" -o "$2" "$1" 2>/dev/null
      '';
    in
    mkThumbnailerEntry {
      name = "mzte-thumbnailer-openscad";
      mime = "application/x-openscad;";
      exec = "${scadthumb} %i %o";
    };

  # See: https://docs.xfce.org/xfce/tumbler/available_plugins#customized_thumbnailer_for_stl_content
  output.packages.mzte-thumbnailer-stl =
    let
      stlthumb = pkgs.writeShellScript "stlthumb" ''
        if TEMP=$(mktemp --directory --tmpdir tumbler-stl-XXXXXX); then
          cp "$1" "$TEMP/source.stl"
          echo 'import("source.stl", convexity=10);' > "$TEMP/thumbnail.scad"
          ${pkgs.openscad-unstable}/bin/openscad --imgsize "500,500" -o "$2" "$TEMP/thumbnail.scad" 2>/dev/null
          rm -rf $TEMP
        fi
      '';
    in
    mkThumbnailerEntry {
      name = "mzte-thumbnailer-stl";
      mime = "model/stl;";
      exec = "${stlthumb} %i %o";
    };
}
