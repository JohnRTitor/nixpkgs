{ lib
, fetchFromGitHub
, rustPlatform
}:

rustPlatform.buildRustPackage rec {
  pname = "libhdr10plus";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "quietvoid";
    repo = "hdr10plus_tool";
    rev = "a26b08587615c7a1f6ef71970484aa0ea40b24a0";
    hash = "sha256-wFl7tykFFL3nFnSA1Y6QMKDaAHugLXJt2TDbeu/dd5s=";
  };

  sourceRoot = "source/hdr10plus";

  cargoPatches = [
    ./Add-cargo-lock.patch
  ];

  cargoHash = "sha256-KolvWMw5SYPOuOJfg//CYe6Wvb1634cI4gwY3IKP8pI=";

  meta = with lib; {
    description = "Library to read & write HDR10+ metadata";
    homepage = "https://github.com/quietvoid/hdr10plus_tool/tree/main/hdr10plus";
    license = licenses.mit;
    maintainers = with maintainers; [ johnrtitor ];
  };
}