{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (builtins) concatStringsSep;
  # Enable only for selected browsers.
  browsers =
    (lib.optional config.programs.firefox.enable "firefox")
    ++ (lib.optional config.programs.chromium.enable "chromium");
in {
  xdg.configFile."psd/psd.conf".text = ''
    USE_OVERLAYFS="${
      if pkgs.stdenv.hostPlatform.isLinux
      then "yes"
      else "no"
    }"

    BROWSERS=(${concatStringsSep " " browsers})

    BACKUP_LIMIT=3
  '';
}
