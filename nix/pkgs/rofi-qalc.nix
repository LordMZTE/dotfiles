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
  version = "0-unstable-2025-10-31";

  src = fetchFromGitHub {
    owner = "svenvvv";
    repo = "rofi-qalc";
    rev = "7b0ff96e7d1dedbe660b1e5a45b15fb946334985";
    hash = "sha256-Lq7ij7FOsbwV9D09rJxgxTFN6aQ5jHprv5wUVSTbOxg=";
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
