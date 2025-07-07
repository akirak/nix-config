{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.claude-code;

  inherit (lib) mkEnableOption mkIf mkOption types;
in {
  options = {
    programs.claude-code = {
      enable = mkEnableOption "claude-code";

      package = mkOption {
        type = types.package;
        default = pkgs.claude-code;
        description = "The claude-code package to install.";
      };

      # settings = mkOption {
      #   type = types.attrs;
      #   default = {};
      #   description = "User-wide options for Claude Code.";
      # };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      cfg.package
    ];

    # home.file.".claude/settings.json".text = builtins.toJSON cfg.settings;
  };
}
