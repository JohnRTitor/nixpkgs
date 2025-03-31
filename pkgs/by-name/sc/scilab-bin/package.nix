{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  undmg,
  autoPatchelfHook,
  alsa-lib,
  fontconfig,
  libgbm,
  ncurses5,
  libxxf86vm,
  libxtst,
  libxrender,
  libxrandr,
  libxi,
  libxft,
  libxext,
  libxcursor,
  libx11,
}:

let
  pname = "scilab-bin";
  version = "2025.0.0";

  srcs = {
    aarch64-darwin = fetchurl {
      url = "https://www.scilab.org/download/${version}/scilab-${version}-arm64.dmg";
      hash = "sha256-hQFETzQiguqiVKBuIrce62eYEJ066B1lHN0IejNUaPQ=";
    };
    x86_64-linux = fetchurl {
      url = "https://www.scilab.org/download/${version}/scilab-${version}.bin.x86_64-linux-gnu.tar.xz";
      hash = "sha256-905HpjpNWnupJ7/fl0Xj7ePDpeMVi02OnEyIeawNdxw=";
    };
  };
  src =
    srcs.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  meta = {
    homepage = "http://www.scilab.org/";
    description = "Scientific software package for numerical computations (Matlab lookalike)";
    platforms = [
      "aarch64-darwin"
      "x86_64-linux"
    ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.gpl2Only;
    mainProgram = "scilab";
  };

  darwin = stdenv.mkDerivation {
    inherit
      pname
      version
      src
      meta
      ;

    nativeBuildInputs = [
      makeWrapper
      undmg
    ];

    sourceRoot = "scilab-${version}.app";

    installPhase = ''
      runHook preInstall

      mkdir -p $out/{Applications/scilab.app,bin}
      cp -R . $out/Applications/scilab.app
      makeWrapper $out/{Applications/scilab.app/Contents/MacOS,bin}/scilab

      runHook postInstall
    '';

    dontCheckForBrokenSymlinks = true;
  };

  linux = stdenv.mkDerivation {
    inherit
      pname
      version
      src
      meta
      ;

    nativeBuildInputs = [
      autoPatchelfHook
    ];

    buildInputs = [
      alsa-lib
      fontconfig
      libgbm
      ncurses5
      stdenv.cc.cc
      libx11
      libxcursor
      libxext
      libxft
      libxi
      libxrandr
      libxrender
      libxtst
      libxxf86vm
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      mv -t $out bin include lib share thirdparty
      sed -i \
        -e 's|\$(/bin/|$(|g' \
        -e 's|/usr/bin/||g' \
        $out/bin/{scilab,xcos}
      sed -i \
        -e "s|Exec=|Exec=$out/bin/|g" \
        -e "s|Terminal=.*$|Terminal=true|g" \
        $out/share/applications/*.desktop

      runHook postInstall
    '';

    # The bundled JRE's AWT libraries load libfontconfig with dlopen() instead
    # of linking it, so autoPatchelfHook never sees a missing dependency and
    # adds no RPATH entry for it. Without it the font manager cannot
    # initialise and Scilab aborts with 'sun.awt.FontConfiguration.head is
    # null' as soon as it renders anything.
    appendRunpaths = [ "${lib.getLib fontconfig}/lib" ];

    dontCheckForBrokenSymlinks = true;
  };
in
if stdenv.hostPlatform.isDarwin then darwin else linux
