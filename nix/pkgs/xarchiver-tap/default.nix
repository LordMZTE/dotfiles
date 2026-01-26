{ stdenvNoCC
, ghc
}:
stdenvNoCC.mkDerivation {
  pname = "xarchiver-tap";
  version = "0";
  src = ./xarchiver-tap.hs;

  dontUnpack = true;

  nativeBuildInputs = [ ghc ];

  buildPhase = ''
    mkdir -p $out/bin
    ghc $src -o $out/bin/xarchiver.tap -O3
  '';
}
