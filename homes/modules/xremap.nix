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

  # Like Command key on Mac.
  naiveAltToCtrlRemaps = {
    "M-a" = "C-a";
    "M-b" = "C-b";
    "M-c" = "C-c";
    "M-d" = "C-d";
    "M-e" = "C-e";
    "M-f" = "C-f";
    "M-g" = "C-g";
    "M-h" = "C-h";
    "M-i" = "C-i";
    "M-j" = "C-j";
    "M-k" = "C-k";
    "M-l" = "C-l";
    "M-m" = "C-m";
    "M-n" = "C-n";
    "M-o" = "C-o";
    "M-p" = "C-p";
    "M-q" = "C-q";
    "M-r" = "C-r";
    "M-s" = "C-s";
    "M-t" = "C-t";
    "M-u" = "C-u";
    "M-v" = "C-v";
    "M-w" = "C-w";
    "M-x" = "C-x";
    "M-y" = "C-y";
    "M-z" = "C-z";
  };

  macBasicRemaps = {
    "M-c" = "C-c";
    "M-v" = "C-v";
    "M-x" = "C-x";
    "M-f" = "C-f";
    "M-a" = "C-a";
    "M-r" = "C-r";
    "M-l" = "C-l";
    "M-w" = "C-w";
    "M-t" = "C-t";
    "M-s" = "C-s";
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
    modmap = [
      {
        name = "Native";
        mode = "default";
        remap = {
          CapsLock = "Control_L";
        };
      }
    ];

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
        remap = basicEmacsRemaps // naiveAltToCtrlRemaps;
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
