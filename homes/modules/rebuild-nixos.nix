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

      directory = lib.mkOption {
        type = types.str;
        description = "Directory containing the NixOS configuration";
        default = "$HOME/build/nix-config";
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
      (pkgs.writeShellScriptBin "nixos-rebuild-and-notify" ''
        operation="''${1:-switch}"
        shift

        if emacs_config="$(readlink -e "${cfg.emacsConfigDirectory}")"
        then
          build_flags=(--override-input emacs-config "''${emacs_config}")
        else
          build_flags=()
        fi

        hostname="$(uname -n)"

        function build_and_switch() {
           local artifact
           cd "${cfg.directory}"

           nix flake update emacs-config

           artifact=$(${pkgs.nix-output-monitor}/bin/nom build \
             ".#nixosConfigurations.$hostname.config.system.build.toplevel" \
             --option accept-flake-config true \
             --no-write-lock-file \
             --print-out-paths \
             --no-link \
             --print-build-logs \
             ''${build_flags[@]}) \
             "''${@}"
           if [[ $? -eq 0 ]]
           then
             sudo nix-env -p /nix/var/nix/profiles/system --set "$artifact" \
               && sudo "$artifact/bin/switch-to-configuration" "$operation"
           else
             return 1
           fi
        }

        if build_and_switch "''${@}"; then
          ${notify} -t 5000 "nixos-rebuild $operation has finished successfully"
        else
          ${notify} -t 5000 "nixos-rebuild $operation has failed"
          read
        fi
      '')
    ];
  };
}
