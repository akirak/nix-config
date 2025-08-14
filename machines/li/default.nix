{ homeUser, pkgs, ... }:
let
  stateVersion = "25.05";

  mainMonitor = {
    criteria = "Unknown VA32AQ K3LMAS000141 (HDMI-A-2)";
    mode = "2560x1440";
    position = "1920,0";
  };

  subMonitor = {
    criteria = "Dell Inc. DELL S2421HS CBPT223 (DP-1)";
    mode = "1920x1080";
    position = "0,380";
  };
in
{
  imports = [
    ./boot.nix
    ./rpool5
    ../../nixos/suites/base
    ../../nixos/suites/graphical
    ../../nixos/suites/desktop
    ../../nixos/profiles/locale
    ../../nixos/profiles/home-manager
    ../../nixos/profiles/nix
    ../../nixos/profiles/sudo
    ../../nixos/profiles/tailscale
    # ../../nixos/profiles/rabbitmq/development.nix
    ../../nixos/profiles/networking/usb-tether1.nix
    ../../nixos/profiles/wayland/wm/hyprland.nix
    ../../nixos/profiles/wayland/cage/foot.nix
    # ../../nixos/profiles/wayland/wm/river.nix
    # ../../nixos/profiles/nix/cachix-deploy.nix
    ../../nixos/profiles/postgresql/development.nix
    ../../nixos/profiles/livebook
    ../../nixos/profiles/ollama
    # ../../nixos/profiles/virtualbox-host
    ../../nixos/profiles/dpt-rp1
    ../../nixos/profiles/podman/rootless-docker.nix
    ../../nixos/profiles/ai-mcp
    # ../../nixos/profiles/docker/rootless.nix
    # ../../nixos/profiles/docker
    # ../../nixos/profiles/docker/kind.nix
    # ../../nixos/profiles/k3s/single-node-for-testing.nix
  ];

  hardware.graphics = {
    enable = true;
    extraPackages = [
      pkgs.intel-compute-runtime
      pkgs.intel-media-driver
    ];
  };

  system.stateVersion = stateVersion;

  # Needed for the ZFS pool.
  networking.hostId = "8425e349";

  # I didn't use disko when I first set up this machine.
  # disko.devices = import ./disko.nix {};

  networking = {
    useDHCP = false;
    networkmanager.enable = true;
  };
  # systemd.services.NetworkManager-wait-online.enable = true;

  environment.systemPackages = [
    pkgs.clinfo
    pkgs.hunspellDicts.en_US
    pkgs.hunspellDicts.en_GB-ise

    # Install Cloud Hypervisor for use with MicroVM
    pkgs.cloud-hypervisor
  ];

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
      "docker"
      "livebook"
    ];
  };

  services.greetd = {
    enable = true;
    settings.default_session = {
      # You have to install *.desktop files to the directory
      command = "${pkgs.greetd.tuigreet}/bin/tuigreet -t -s /etc/wayland-sessions";
      user = homeUser;
    };
  };

  services.my-livebook = {
    enable = false;
    settings = {
      ipAddress = "127.0.0.1";
      port = 8200;
      enableNix = true;
    };
  };

  services.ollama.acceleration = false;

  services.postgresql = {
    package = pkgs.postgresql_17;
  };

  home-manager.users.${homeUser} = {
    imports = [
      ../../homes/basic.nix
      ../../homes/extra.nix
      ../../homes/code.nix
      ../../homes/graphical.nix
    ];

    programs.chromium = {
      enable = true;
      package = pkgs.ungoogled-chromium;
    };

    programs.uv.settings = {
      # ZFS
      link-mode = "copy";
    };

    home.stateVersion = stateVersion;

    home.packages = [
      pkgs.rclone
      # pkgs.steam-run
      # pkgs.wine
      # pkgs.tenacity
      # pkgs.microsoft-edge
      # pkgs.zoom-us
    ];

    home.file.".npmrc".text = ''
      # Required because of the network instability
      fetch-retries = 5
      # Required because of ZFS
      package-import-method=copy
    '';

    services.kanshi.settings = [
      {
        profile.name = "docked";
        profile.outputs = [
          mainMonitor
          subMonitor
        ];
      }
      {
        profile.name = "undocked";
        profile.outputs = [ mainMonitor ];
      }
      {
        profile.name = "as_secondary";
        profile.outputs = [ subMonitor ];
      }
    ];

    wayland.windowManager.hyprland.enable = true;

    # programs.river.enable = true;

    programs.gpg.enable = true;

    programs.emacs-twist = {
      enable = true;
      settings = {
        enableJava = true;
        extraFeatures = [
          "beancount"
          "OCaml"
          "Emacs"
          "Emacs__lisp"
          "Org"
          "MCP"
          "writing"
          # "Coq"
          # "Lean4"
          # "lsp_mode"
        ];
      };
    };
  };
}
