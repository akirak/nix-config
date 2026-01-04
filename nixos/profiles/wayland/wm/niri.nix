{
  imports = [
    ../sessions.nix
  ];

  programs.niri = {
    enable = true;
  };

  # Based on https://danklinux.com/docs/dankmaterialshell/nixos
  programs.dms-shell = {
    enable = true;

    systemd = {
      enable = true; # Systemd service for auto-start
      restartIfChanged = true; # Auto-restart dms.service when dms-shell changes
    };

    # Core features
    enableSystemMonitoring = true; # System monitoring widgets (dgop)
    # enableClipboard = true; # Clipboard history manager
    # enableVPN = true; # VPN management widget
    # enableDynamicTheming = true; # Wallpaper-based theming (matugen)
    enableAudioWavelength = true; # Audio visualizer (cava)
    enableCalendarEvents = true; # Calendar integration (khal)
  };

  # environment.systemPackages = [
  #   pkgs.wev
  # ];

  wayland.sessions = [
    {
      name = "Niri";
      exec = "niri-session";
    }
  ];
}
