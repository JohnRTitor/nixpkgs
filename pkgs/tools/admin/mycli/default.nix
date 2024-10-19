{ lib
, python3Packages
, fetchPypi
, glibcLocales
}:
let
  paramiko = python3Packages.paramiko.overrideAttrs (finalAttrs: prevAttrs: {
    version = "3.4.1";
    src = fetchPypi {
      inherit (prevAttrs) pname;
      inherit (finalAttrs) version;
      hash = "sha256-ixUwKHCvf2ZS8uA4l1wdKXPwYEbLXX1lNVZos+y+zgw=";
    };
  });
in python3Packages.buildPythonApplication rec {
  pname = "mycli";
  version = "1.27.2";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-0R2k5hRkAJbqgGZEPXWUb48oFxTKMKiQZckf3F+VC3I=";
  };

  propagatedBuildInputs = (with python3Packages; [
    cli-helpers
    click
    configobj
    importlib-resources
    prompt-toolkit
    pyaes
    pycrypto
    pygments
    pymysql
    pyperclip
    sqlglot
    sqlparse
  ]) ++ [ paramiko ];

  nativeCheckInputs = [ python3Packages.pytestCheckHook glibcLocales ];

  preCheck = ''
    export HOME=.
    export LC_ALL="en_US.UTF-8"
  '';

  disabledTestPaths = [
    "mycli/packages/paramiko_stub/__init__.py"
  ];

  meta = with lib; {
    inherit version;
    description = "Command-line interface for MySQL";
    mainProgram = "mycli";
    longDescription = ''
      Rich command-line interface for MySQL with auto-completion and
      syntax highlighting.
    '';
    homepage = "http://mycli.net";
    license = licenses.bsd3;
    maintainers = with maintainers; [ jojosch ];
  };
}
