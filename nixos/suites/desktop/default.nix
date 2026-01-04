{
  homeUser,
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    ../../profiles/yubikey
    ../../profiles/users/primary-group.nix
  ];

  environment.systemPackages = [
    # Mostly copy-and-pasted from nixos/modules/profiles/base.nix in
    # nixos/nixpkgs.
    pkgs.ms-sys
    pkgs.efibootmgr
    pkgs.efivar
    pkgs.parted
    pkgs.gptfdisk
    pkgs.ddrescue
    pkgs.ccrypt
    pkgs.cryptsetup
    pkgs.vim
    pkgs.fuse
    pkgs.fuse3
    pkgs.sshfs-fuse
    pkgs.socat
    pkgs.screen
    pkgs.tcpdump
    pkgs.sdparm
    pkgs.hdparm
    pkgs.smartmontools
    pkgs.pciutils
    pkgs.usbutils
    pkgs.nvme-cli
    pkgs.unzip
    pkgs.zip

    pkgs.lsof
    pkgs.psmisc
    pkgs.handlr
    pkgs.libnotify
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

  # https://github.com/xremap/xremap?tab=readme-ov-file#nixos-1
  hardware.uinput.enable = true;
  boot.kernelModules = [ "uinput" ];
  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", TAG+="uaccess"
  '';
}
