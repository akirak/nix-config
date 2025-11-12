{
  homeUser,
  pkgs,
  ...
}:
let
  stateVersion = "25.05";
in
{
  imports = [
    ./boot.nix
    ../../nixos/suites/base
    ../../nixos/suites/graphical
    ../../nixos/suites/desktop
    ../../nixos/profiles/locale
    ../../nixos/profiles/home-manager
    ../../nixos/profiles/nix
    ../../nixos/profiles/sudo
    ../../nixos/profiles/tailscale
    ../../nixos/profiles/wayland/wlroots.nix
    # ../../nixos/profiles/wayland/cage/emacs.nix
    ../../nixos/profiles/wayland/cage/foot.nix
    # ../../nixos/profiles/wayland/cage/firefox.nix
    # ../../nixos/profiles/wayland/wm/labwc.nix
    ../../nixos/profiles/wayland/wm/hyprland.nix
    # ../../nixos/profiles/nix/cachix-deploy.nix
    ../../nixos/profiles/dpt-rp1
  ];

  networking = {
    firewall.enable = true;
    useDHCP = false;
    networkmanager.enable = true;
  };

  system.stateVersion = stateVersion;

  hardware.graphics.enable = true;

  systemd.services.NetworkManager-wait-online.enable = false;

  services.journald.extraConfig = ''
    SystemMaxFiles=5
  '';

  services.auto-cpufreq.enable = true;

  zramSwap = {
    enable = true;
  };

  users.users.${homeUser} = {
    description = "Akira Komamura";
    uid = 1000;
    isNormalUser = true;
    hashedPassword = "$6$3LmgpFGu4WEeoTss$9NQpF4CEO8ivu0uJTlDYXdiB6ZPHBsLXDZr.6S59bBNxmNuhirmcOmHTwhccdgSwq7sJOz2JbOOzmOCivxdak0";

    extraGroups = [
      "wheel"
      "video"
      "audio"
      "disk"
      "networkmanager"
      "systemd-journal"
      # "docker"
    ];
  };

  services.greetd = {
    enable = true;
    settings.default_session = {
      # You have to install *.desktop files to the directory
      command = "${pkgs.tuigreet}/bin/tuigreet -t -s /etc/wayland-sessions";
      user = homeUser;
    };
  };

  home-manager.users.${homeUser} = {
    imports = [
      ../../homes/basic.nix
      ../../homes/extra.nix
      ../../homes/graphical.nix
    ];

    # wayland.windowManager.labwc.enable = true;
    wayland.windowManager.hyprland.enable = true;

    programs.gpg.enable = true;

    programs.emacs-twist = {
      enable = true;
      serviceIntegration.enable = false;
      settings = {
        extraFeatures = [
          "beancount"
          "OCaml"
          "Emacs"
          "Emacs__lisp"
          "Org"
        ];
      };
    };
  };
}
