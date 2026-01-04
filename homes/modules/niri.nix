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
  };

  options = {
    programs.niri = {
      enable = lib.mkEnableOption "Enable Niri.";
    };
  };
}
