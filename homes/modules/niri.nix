{
  config,
  lib,
  ...
}:
let
  cfg = config.programs.niri;
in
{
  config = lib.mkIf cfg.enable {
    xdg.configFile."niri/config.kdl".source = ../etc/niri/config.kdl;

    # Requires the home module from the xremap flake
    services.xremap.withNiri = true;
  };

  options = {
    programs.niri = {
      enable = lib.mkEnableOption "Enable Niri.";
    };
  };
}
