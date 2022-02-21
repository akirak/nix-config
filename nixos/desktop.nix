{
  imports = [
    ./base.nix
    ./baremetal.nix
    ./profiles/graphical.nix
    ./profiles/yubikey.nix
  ];

  nix = {
    gc = {
      dates = "2weeks";
      automatic = true;
    };
    optimise.automatic = false;

    useSandbox = true;

    allowedUsers = [ "@wheel" ];

    trustedUsers = [ "root" "@wheel" ];

    extraOptions = ''
      min-free = 536870912
      keep-outputs = true
      keep-derivations = true
      fallback = true
    '';
  };

  # Allow mounting FUSE filesystems as a user.
  # https://discourse.nixos.org/t/fusermount-systemd-service-in-home-manager/5157
  environment.etc."fuse.conf".text = ''
    user_allow_other
  '';

  # Necessary if you want to turn on allowOther in impermanence
  # https://github.com/nix-community/impermanence
  # programs.fuse.userAllowOther = true;

  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;
  security.sudo.execWheelOnly = true;

  services.earlyoom.enable = true;

  services.psd.enable = true;
}
