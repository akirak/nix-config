{
  modulesPath,
  homeUser,
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    (modulesPath + "/profiles/base.nix")
    ../../profiles/yubikey
    ../../profiles/users/primary-group.nix
  ];

  environment.systemPackages = [
    pkgs.lsof
    pkgs.psmisc
    pkgs.handlr
    pkgs.libnotify
    pkgs.wireguard-tools
  ] ++ lib.optional config.services.postgresql.enable pkgs.pgcli;

  environment.sessionVariables = {
    "TMPDIR" = "/tmp";
  };

  networking.usePredictableInterfaceNames = true;

  time.timeZone = "Asia/Tokyo";

  services.earlyoom.enable = true;
  services.psd.enable = true;

  # Allow mounting FUSE filesystems as a user.
  # https://discourse.nixos.org/t/fusermount-systemd-service-in-home-manager/5157
  environment.etc."fuse.conf".text = ''
    user_allow_other
  '';

  programs.nix-ld.enable = true;

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = lib.mkDefault "--keep-since 18d --keep 3";
    flake = "/home/${homeUser}/build/nix-config";
  };
}
