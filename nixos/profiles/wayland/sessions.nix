{
  config,
  lib,
  ...
}: let
  inherit (lib) mkOption types;

  session = types.submodule {
    options.name = mkOption {
      type = types.str;
      example = "firefox-session";
    };
    options.desktopName = mkOption {
      type = types.nullOr types.str;
      example = "Firefox Session";
      default = null;
    };
    options.exec = mkOption {
      type = types.nullOr types.str;
      example = "firefox-session";
      default = null;
    };
  };
in {
  options = {
    wayland.sessions = mkOption {
      type = types.listOf session;
      default = [];
    };
  };

  config = {
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    environment.etc = builtins.listToAttrs (builtins.map
      ({
        name,
        desktopName,
        exec,
      }: {
        name = "wayland-sessions/${name}.desktop";
        value = {
          text = ''
            [Desktop Entry]
            Name=${
              if desktopName != null
              then desktopName
              else name
            }
            Exec=${
              if exec != null
              then exec
              else name
            }
            Type=Application
          '';
        };
      })
      config.wayland.sessions);
  };
}
