{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
}:

let
  pname = "erigon";
  version = "3.0.3";
in
buildGoModule {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "ledgerwatch";
    repo = "erigon";
    rev = "v${version}";
    hash = "sha256-gSgkdg7677OBOkAbsEjxX1QttuIbfve2A3luUZoZ5Ik=";
    fetchSubmodules = true;
  };

  vendorHash = "sha256-8eyC3JkRcRlFw8CyTK5w1XySur2jAeFGXkEaY/3Oq0k=";
  proxyVendor = true;

  # Build errors in mdbx when format hardening is enabled:
  #   cc1: error: '-Wformat-security' ignored without '-Wformat' [-Werror=format-security]
  hardeningDisable = [ "format" ];

  # Fix error: 'Caught SIGILL in blst_cgo_init'
  # https://github.com/bnb-chain/bsc/issues/1521
  CGO_CFLAGS = "-O -D__BLST_PORTABLE__";
  CGO_CFLAGS_ALLOW = "-O -D__BLST_PORTABLE__";

  subPackages = [
    "cmd/erigon"
    "cmd/evm"
    "cmd/rpcdaemon"
    "cmd/rlpdump"
  ];

  # Matches the tags to upstream's release build configuration
  # https://github.com/ledgerwatch/erigon/blob/0c0dbe5f3a81cf8f16da8e4838312ab80ebe5302/.goreleaser.yml
  #
  # Enabling silkworm also breaks the build as it requires dynamically linked libraries.
  # If we need it in the future, we should consider packaging silkworm and silkworm-go
  # as depenedencies explicitly.
  tags = [
    "nosqlite"
    "noboltdb"
    "nosilkworm"
  ];

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    homepage = "https://github.com/ledgerwatch/erigon/";
    description = "Ethereum node implementation focused on scalability and modularity";
    license = with licenses; [
      lgpl3Plus
      gpl3Plus
    ];
    maintainers = with maintainers; [
      d-xo
      happysalada
    ];
  };
}
