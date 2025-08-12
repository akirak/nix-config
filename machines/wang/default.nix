{
  pkgs,
  modulesPath,
  ...
}:
let
  stateVersion = "25.05";
in
{
  imports = [
    # basics
    (modulesPath + "/profiles/hardened.nix")
    (modulesPath + "/profiles/headless.nix")
    ../../nixos/suites/server
    ./fs
    ./boot.nix

    ../../nixos/profiles/networking/r8168.nix

    # Create a non-wheel user for hosting some personal data.
    ../../nixos/profiles/users/1000/on-server.nix
  ];

  system.stateVersion = stateVersion;

  # Needed for the ZFS pool.
  # Use `cat /etc/machine-id | cut -c1-8`
  networking.hostId = "4cc22902";

  boot.runSize = "64m";
  boot.devSize = "256m";
  boot.devShmSize = "256m";

  services.auto-cpufreq.enable = true;
  powerManagement.cpuFreqGovernor = "ondemand";

  environment.systemPackages = [
    pkgs.lshw
    pkgs.usbutils
    pkgs.pkgs.git
    pkgs.git-annex
    # Install gdisk to allow working with new storage devices while the server
    # is online.
    pkgs.gptfdisk
  ];

  time.timeZone = "Asia/Tokyo";
}
