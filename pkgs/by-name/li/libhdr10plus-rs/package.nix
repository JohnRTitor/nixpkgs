{ lib
, fetchFromGitHub
, rustPlatform
}:

rustPlatform.buildRustPackage rec {
  pname = "libhdr10plus-rs";
  version = "2.1.2";

  src = fetchFromGitHub {
    owner = "quietvoid";
    repo = "hdr10plus_tool";
    rev = "libhdr10plus-2.1.2";
    hash = "sha256-rZ0ZQKTz59ZwZv6OXZM6KM3EnpAo5CuhhC9eHLlhfdI=";
  };

  buildAndTestSubdir = "hdr10plus";

  cargoHash = "sha256-869pdb1vzu3HWbt7BLSNb8087Wjtec8ovoKTOCV2Btg=";

  meta = with lib; {
    description = "Library to read & write HDR10+ metadata";
    pkgConfigModules = [ "libhdr10plus-rs" "hdr10plus-rs" ];
    homepage = "https://github.com/quietvoid/hdr10plus_tool/tree/main/hdr10plus";
    license = licenses.mit;
    maintainers = with maintainers; [ johnrtitor ];
  };
}