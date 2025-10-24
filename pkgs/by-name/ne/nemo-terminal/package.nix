{
  stdenv,
  lib,
  fetchFromGitHub,
  pkg-config,
  glib,
  gobject-introspection,
  gtk3,
  vte,
  gettext,
  nemo-python,
  dconf,
  python3Packages,
}:

python3Packages.buildPythonApplication rec {
  pname = "nemo-terminal";
  version = "6.4.0";

  src = fetchFromGitHub {
    owner = "linuxmint";
    repo = "nemo-extensions";
    tag = version;
    hash = "sha256-39hWA4SNuEeaPA6D5mWMHjJDs4hYK7/ZdPkTyskvm5Y=";
  };

  sourceRoot = "${src.name}/nemo-terminal";

  postPatch = ''
    substituteInPlace setup.py --replace-fail '/usr/' '${placeholder "out"}/'

    substituteInPlace src/nemo-terminal-prefs --replace-fail '/usr/share' '${placeholder "out"}/share'

    substituteInPlace src/nemo_terminal.py --replace-fail '/usr/share' '${placeholder "out"}/share'
  '';

  pyproject = true;
  build-system = [ python3Packages.setuptools ];

  nativeBuildInputs = [
    pkg-config
    gobject-introspection
  ];

  propagatedBuildInputs = [
    glib
    gtk3
    vte
    nemo-python
    dconf
    gettext
  ];

  postInstall = ''
    # patching setup.py messes up the install location, so move files around to their proper place
    mv $out/lib/python3.*/site-packages/$out/* $out/
    rm -rf $out/lib/python3.*/site-packages/nix

    glib-compile-schemas $out/share/glib-2.0/schemas
  '';

  meta = {
    homepage = "https://github.com/linuxmint/nemo-extensions/tree/master/nemo-terminal";
    changelog = "https://github.com/linuxmint/nemo-extensions/blob/master/nemo-terminal/debian/changelog";
    description = "Embedded terminal extension for Nemo file-manager";
    longDescription = ''
      You can add the extension to nemo using the following configuration:
      ```nix
      {
        environment.systemPackages = with pkgs; [
          (nemo-with-extensions.override {
            extensions = [ nemo-terminal ];
          })
        ];
      }
      ```
    '';
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
    maintainers = [ lib.maintainers.johnrtitor ];
    teams = [ lib.teams.cinnamon ];
  };
}
