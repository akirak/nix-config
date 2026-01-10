{ homeUser, ... }:
let
  stateVersion = "25.11";
in
{
  system.stateVersion = stateVersion;

  imports = [
    ../../nixos/suites/base
    ../../nixos/profiles/locale
    ../../nixos/profiles/home-manager
    # ../../nixos/profiles/nix
    ../../nixos/profiles/sudo
    # ../../nixos/profiles/tailscale
    ../../nixos/profiles/podman/rootless-docker.nix
  ];

  # time.timeZone = "Asia/Tokyo";

  home-manager.users.${homeUser} = {
    imports = [
      ../../homes/basic.nix
    ];

    programs.emacs-twist = {
      enable = true;
      settings = {
        extraFeatures = [
          "Emacs"
          "Emacs__lisp"
          "Org"
          "MCP"
          "writing"
          "Lean4"
        ];
      };
    };
  };
}
