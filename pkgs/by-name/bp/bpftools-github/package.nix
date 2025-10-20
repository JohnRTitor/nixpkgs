{
  lib,
  stdenv,
  fetchFromGitHub,
  buildPackages,
  libopcodes,
  libcap,
  libbfd,
  elfutils,
  readline,
  zlib,
  python3,
  bison,
  flex,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "bpftools";
  version = "7.6.0";

  src = fetchFromGitHub {
    owner = "libbpf";
    repo = "bpftool";
    tag = "v${finalAttrs.version}";
    hash = "sha256-OdRRyObucyootz7cwXT39VuH5iAnpIk1u0sf7ajCIm0=";
    fetchSubmodules = true;
  };

  postPatch = ''
    substituteInPlace ./src/Makefile \
      --replace-fail '/usr/local' '${placeholder "out"}' \
      --replace-fail '/usr/share' '${placeholder "out"}/share'

    substituteInPlace ./docs/Makefile \
      --replace-fail '/usr/local' '${placeholder "out"}'
  '';

  separateDebugInfo = true;

  depsBuildBuild = [ buildPackages.stdenv.cc ];
  nativeBuildInputs = [
    python3
    bison
    flex
  ];

  buildInputs = [
    elfutils
    zlib
    readline
    libopcodes
    libbfd
    libcap
  ];

  preConfigure = ''
    cd src/
  '';

  makeFlags = [
    "PREFIX=${placeholder "out"}"
    # needed for cross to riscv64
    "ARCH=${stdenv.hostPlatform.linuxArch}"
  ];

  meta = {
    homepage = "https://github.com/libbpf/bpftool";
    description = "Debugging/program analysis tools for the eBPF subsystem";
    license = with lib.licenses; [
      gpl2Only
      bsd2
    ];
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ johnrtitor ];
  };
})
