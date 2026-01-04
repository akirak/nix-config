let
  basicEmacsRemaps = {
    "C-p" = "up";
    "C-n" = "down";
    "C-b" = "left";
    "C-f" = "right";
    "C-a" = "home";
    "C-e" = "end";
    "C-d" = "delete";
  };

  macBasicRemaps = {
    "M-c" = "C-c";
    "M-v" = "C-v";
    "M-x" = "C-x";
    "M-f" = "C-f";
    "M-a" = "C-a";
    "M-r" = "C-r";
    "M-l" = "C-l";
  };
in
{
  # This module depends on https://github.com/xremap/nix-flake. See
  # https://github.com/xremap/nix-flake/blob/master/docs/HOWTO.md#user-module
  # for more information

  services.xremap.deviceNames = [
    # Run `ls /dev/input/by-id` to identify the device name.
    # Usually prefixed with "usb-" and suffixed with "-event-kbd".
    "Keychron Keychron K3"
  ];

  services.xremap.config = {
    # modmap = [ ];

    # Use `niri msg pick-window` to identify the application ID.
    keymap = [
      {
        name = "Default";
        application = {
          not = [
            "emacs"
            # Terminal applications
            "foot"
          ];
        };
        remap = basicEmacsRemaps // macBasicRemaps;
      }

      {
        name = "Browser";
        application = {
          only = [
            "zen-beta"
            "chromium-browser"
          ];
        };
        remap = {
          "M-Enter" = "C-Enter";
        };
      }

      {
        name = "Foot";
        application = {
          only = [
            "foot"
          ];
        };
        remap = {
          # Copy and paste
          "M-c" = "C-Shift-c";
          "M-v" = "C-Shift-v";
        };
      }
    ];
  };
}
