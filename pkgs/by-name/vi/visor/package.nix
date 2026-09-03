{
  lib,
  stdenv,
  fetchFromGitHub,
  gnu-efi,
  makeWrapper,
  python3,
  efibootmgr,
  util-linux,
}:

let
  arch =
    if stdenv.hostPlatform.isAarch64 then
      "aarch64"
    else if stdenv.hostPlatform.isx86_64 then
      "x86_64"
    else
      throw "Unsupported architecture";
  efiFileName = if stdenv.hostPlatform.isAarch64 then "visor_aa64.efi" else "visor_x64.efi";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "visor";
  version = "1.4";

  src = fetchFromGitHub {
    owner = "IO-ZetZor";
    repo = "Visor-BootManager";
    tag = "v${finalAttrs.version}";
    sha256 = "1pc4w2ahzf52mivghg0jgpy9b8np44c4zg5ywhr3zr0c98gxai5z";
  };

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [ gnu-efi ];

  makeFlags = [
    "ARCH=${arch}"
    "GNU_EFI_INC=${gnu-efi}/include/efi"
    "CRT0=${gnu-efi}/lib/crt0-efi-${arch}.o"
  ];

  postPatch = ''
    substituteInPlace visor \
      --replace-fail 'PKG_LIB_DIR="''${VISOR_LIB_DIR:-/usr/lib/visor}"' 'PKG_LIB_DIR="''${VISOR_LIB_DIR:-'"$out"'/lib/visor}"' \
      --replace-fail 'PKG_DATA_DIR="''${VISOR_DATA_DIR:-/usr/share/visor}"' 'PKG_DATA_DIR="''${VISOR_DATA_DIR:-'"$out"'/share/visor}"'
  '';

  installPhase = ''
    runHook preInstall

    install -Dm644 ${efiFileName} -t $out/lib/visor

    install -Dm755 visor -t $out/bin

    install -Dm644 boot.conf.example docs/boot.conf.schema.json -t $out/share/visor
    cp -r assets/icons assets/backgrounds assets/logo.png $out/share/visor/

    install -Dm755 tools/visor_encrypt.py -t $out/share/visor/tools

    runHook postInstall
  '';

  postInstall = ''
    wrapProgram $out/bin/visor \
      --prefix PATH : ${
        lib.makeBinPath [
          efibootmgr
          util-linux
          python3
        ]
      }
  '';

  meta = {
    description = "A minimal, fast, graphical UEFI boot manager";
    homepage = "https://github.com/IO-ZetZor/Visor-BootManager";
    license = lib.licenses.bsd2;
    mainProgram = "visor";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    maintainers = with lib.maintainers; [ ];
  };
})
