{ lib, pkgs, ... }:
let
  notifyDesktop = pkgs.writeShellApplication {
    name = "claude-code-notify-desktop";
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

  programs.claude-code = {
    settings.hooks = {
      Notification = [
        {
          matcher = "Bash";
          command = lib.getExe notifyDesktop;
        }
      ];
    };
  };
}
