{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types;

  cfg = config.programs.rebuild-home;

  notify = "${pkgs.notify-desktop}/bin/notify-desktop -r home-manager";
in {
  options = {
    programs.rebuild-home = {
      enable = lib.mkOption {
        type = types.bool;
        description = "Install rebuild-home script";
        default = config.targets.genericLinux.enable || pkgs.stdenv.isDarwin;
      };

      emacsConfigDirectory = lib.mkOption {
        type = types.str;
        description = "Directory containing the Emacs configuration";
        default = "$HOME/build/emacs-config";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.writeShellScriptBin "rebuild-home" ''
        flake="${config.programs.nh.flake}"

        operation="''${1:-switch}"
        shift

        emacs_config="${cfg.emacsConfigDirectory}"
        if [[ -d "''${emacs_config}" ]]
        then
          flags=(--override-input emacs-config "path:$(readlink -f "''${emacs_config}")")
        else
          flags=()
        fi

        if ${lib.getExe pkgs.nh} home "$operation" "$flake" -- ''${build_flags[@]} "''${@}"; then
          ${notify} -t 5000 'Successfully switched to a new home-manager generation'
        else
          ${notify} -t 5000 'Failed to switch to a new home-manager generation'
          read
        fi
      '')
    ];
  };
}
