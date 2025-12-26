{
  config,
  lib,
  pkgs,
  ...
}:
let
  enableFoot = config.programs.foot.enable;
  enableWayland = true;

  defaultBrowser =
    if config.programs.zen-browser.enable then
      config.programs.zen-browser.package.meta.desktopFileName
    else if config.programs.librewolf.enable then
      "librewolf.desktop"
    else if config.programs.firefox.enable then
      "firefox.desktop"
    else
      null;

  defaultApplications = {
    "image/svg+xml" = [
      defaultBrowser
    ];
  };
in
{
  programs = {
    # alacritty.enable = enableGraphical;
    mpv.enable = true;
    foot.enable = enableWayland;
    foot.server.enable = enableFoot;
    # TODO: Add font package
    foot.settings.main.font = "JetBrainsMono NF:size=10.5";

    # See modules/librewolf.nix for details
    # librewolf.enable = true;
    # firefox.enable = true;
    zen-browser.enable = true;

    # AI coding (Cline)
    # vscode.enable = true;

    # enable auto-notify plugin only in graphical environments
    zsh = {
      plugins = [
        {
          name = "auto-notify";
          src = pkgs.customZshPlugins.zsh-auto-notify;
        }
      ];
      sessionVariables = {
        # https://github.com/MichaelAquilina/zsh-auto-notify
        "AUTO_NOTIFY_THRESHOLD" = "60";
      };
      initContent = ''
        export AUTO_NOTIFY_IGNORE=("nix shell" "nix develop" "ssh" "agenix edit" "man" "less")
      '';
    };
  };

  home.packages =
    (with pkgs; [
      blanket
      pavucontrol

      # required by zsh-auto-notify plugin
      libnotify

      # API development
      # hoppscotch

      # database admin
      # beekeeper-studio

      # design
      penpot-desktop

      # fonts
      customFontPackages.jetbrains-mono-nerdfont
      # Japanese
      ipafont
    ])
    ++ lib.optionals enableWayland [
      pkgs.wayshot
      pkgs.wf-recorder
      pkgs.slurp # Used with wayshot
      pkgs.wl-clipboard

      (pkgs.writeShellApplication {
        name = "lock-screen";
        runtimeInputs = [ pkgs.swaylock-effects ];
        # TODO: Use a color scheme
        text = ''
          swaylock -f --clock --fade-in 0.5
        '';
      })
    ];

  xdg.mime.enable = true;
  xdg.mimeApps = lib.mkIf (defaultBrowser != null) {
    enable = true;
    inherit defaultBrowser;
    inherit defaultApplications;
    associations.added = defaultApplications;
  };

  systemd.user.services.emacs = {
    Service = {
      Environment = lib.optionals enableWayland [
        "MOZ_ENABLE_WAYLAND=1"
        "WAYLAND_DISPLAY=wayland-1"
      ];
    };
  };

  systemd.user.services.foot = lib.mkIf config.programs.foot.server.enable {
    Service = {
      Environment = lib.mkForce [
        "WAYLAND_DISPLAY=wayland-1"
        "PATH=${
          lib.concatMapStrings (dir: dir + ":") config.home.sessionPath
        }${config.home.profileDirectory}/bin"
      ];
    };
  };
}
