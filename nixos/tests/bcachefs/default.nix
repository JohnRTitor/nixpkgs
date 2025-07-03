{
  pkgs,
  runTestOn,
  platforms
}:

{
  lts = runTestOn platforms {
    imports = [ ./common.nix ];
    _module.args.kernel = pkgs.linuxPackages;
  };
  latest = runTestOn platforms {
    imports = [ ./common.nix ];
    _module.args.kernel = pkgs.linuxPackages_latest;
  };
  testing = runTestOn platforms {
    imports = [ ./common.nix ];
    _module.args.kernel = pkgs.linuxPackages_testing;
  };
}
