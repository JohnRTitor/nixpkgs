{
  lib,
  stdenv,
  kernel,
  bc,
  kernelModuleMakeFlags,
  fetchFromGitHub,
}:
stdenv.mkDerivation {
  pname = "bcachefs";
  version = "0-unstable-2025-09-10";

  src = fetchFromGitHub {
    owner = "koverstreet";
    repo = "bcachefs-tools";
    rev = "f00a2843aa3e34182f31f34eb9eccc1583aa4940";
    hash = "sha256-Dajv5568Gtz/lDW2n4FgnGNiGqmfLr6tsNb3JB5RG30=";
  };

  hardeningDisable = [ "pic" ];

   nativeBuildInputs = kernel.moduleBuildDependencies;

   postPatch = ''
     substituteInPlace ./dkms/Makefile \
       --replace-fail '/lib/modules/`uname -r`/build' ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build
   '';

   preBuild = ''
     cd dkms
   '';


   buildFlags = [
     "KERNEL_DIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
   ];

   installPhase = ''
     ls
   '';

  meta = {
    description = "Bcachefs";
    homepage = "https://github.com/koverstreet/bcachefs-tools";
    license = lib.licenses.gpl2Only;
    maintainers = [ lib.maintainers.johnrtitor ];
  };
}
