{
  stdenv,
  lib,
  meson,
  ninja,
  sysprof,
}:

stdenv.mkDerivation {
  pname = "libsysprof-capture";

  inherit (sysprof) src version;

  nativeBuildInputs = [
    meson
    ninja
  ];

  mesonFlags = [
    "-Dsysprofd=none"
    "-Dgtk=false"
    "-Dlibsysprof=false"
    "-Dhelp=false"
    "-Dtools=false"
    "-Dtests=false"
    "-Dexamples=false"
    "-Dpolkit-agent=disabled" # only useful for sysprof-cli
    "-Ddebuginfod=disabled"
  ];

  meta = sysprof.meta // {
    description = "Static library for Sysprof capture data generation";
    license = lib.licenses.bsd2Patent;
    platforms = lib.platforms.all;
    pkgConfigModules = [ "sysprof-capture-4" ];
  };
}
