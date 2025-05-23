{
  stdenv,
  lib,
  fetchurl,
  guile,
  pkg-config,
  guile-fibers,
}:

stdenv.mkDerivation rec {
  pname = "gnu-shepherd";
  version = "1.0.4";

  src = fetchurl {
    url = "mirror://gnu/shepherd/shepherd-${version}.tar.gz";
    hash = "sha256-EzBqa1bf4lJGToSiPCOnI0M4zHUsVl4bhl98v4oD8M8=";
  };

  configureFlags = [ "--localstatedir=/" ];

  buildInputs = [
    guile
    guile-fibers
  ];
  nativeBuildInputs = [ pkg-config ];

  meta = with lib; {
    homepage = "https://www.gnu.org/software/shepherd/";
    description = "Service manager that looks after the herd of system services";
    license = with licenses; [ gpl3Plus ];
    platforms = platforms.unix;
    maintainers = with maintainers; [ kloenk ];
  };
}
