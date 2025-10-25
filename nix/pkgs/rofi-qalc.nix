{ stdenv
, fetchFromGitHub
, cairo
, libqalculate
, meson
, ninja
, pkg-config
, rofi-unwrapped
, ...
}:
stdenv.mkDerivation {
  pname = "rofi-qalc";
  version = "0-unstable-2024-07-15";

  src = fetchFromGitHub {
    owner = "svenvvv";
    repo = "rofi-qalc";
    rev = "f79251f071f26694206ee6df84a92ab4fbbb051f";
    hash = "sha256-iwFhHvH1HM/IffZVchhHOfmt4KMKNcqXpP+LMa/mTU4=";
  };

  mesonBuildType = "release";
  mesonFlags = [
    "--libdir=${placeholder "out"}/lib/rofi"
  ];

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
  ];

  buildInputs = [
    cairo
    rofi-unwrapped
    libqalculate
  ];
}
