{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.claude-code;

  notifyDesktop = pkgs.writeShellApplication {
    name = "claude-notify-desktop";
    runtimeInputs = with pkgs; [
      deno
      notify-desktop
    ];
    text = ''
      deno run --allow-run=notify-desktop --allow-env ${./notify-desktop.ts}
    '';
  };
in
{
  imports = [
    ./interface.nix
  ];

  home.packages = lib.optional cfg.enable notifyDesktop;

  programs.claude-code = {
    # settings.hooks = {
    #   Notification = [
    #     {
    #       matcher = "Bash";
    #       command = lib.getExe notifyDesktop;
    #     }
    #   ];
    # };
  };
}
