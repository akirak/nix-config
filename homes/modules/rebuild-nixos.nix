{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types;

  cfg = config.programs.nixos-rebuild-and-notify;

  notify = "${pkgs.notify-desktop}/bin/notify-desktop -r nixos-rebuild";
in
{
  options = {
    programs.nixos-rebuild-and-notify = {
      enable = lib.mkEnableOption (lib.mdDoc "Install nixos-rebuild-and-notify script");

      emacsConfigDirectory = lib.mkOption {
        type = types.str;
        description = "Directory containing the Emacs configuration";
        default = "$HOME/build/emacs-config";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.writeShellScriptBin "nixos-rebuild-and-notify" ''
        flake="${config.programs.nh.flake}"

        operation="''${1:-switch}"
        shift

        if emacs_config="$(readlink -e "${cfg.emacsConfigDirectory}")"
        then
          build_flags=(--override-input emacs-config "''${emacs_config}")
        else
          build_flags=()
        fi

        if ${lib.getExe pkgs.nh} os "$operation" "$flake" -- ''${build_flags[@]} "''${@}"; then
          ${notify} -t 5000 "nixos-rebuild $operation has finished successfully"
        else
          ${notify} -t 5000 "nixos-rebuild $operation has failed"
          read
        fi
      '')
    ];
  };
}
