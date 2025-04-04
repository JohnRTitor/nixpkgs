{
  buildDunePackage,
  faraday-lwt-unix,
  gluten,
  gluten-lwt,
  lwt_ssl,
}:

buildDunePackage {
  pname = "gluten-lwt-unix";
  inherit (gluten)
    doCheck
    meta
    src
    version
    ;

  propagatedBuildInputs = [
    faraday-lwt-unix
    gluten-lwt
    lwt_ssl
  ];
}
