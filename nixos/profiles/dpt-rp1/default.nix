# Connectivity with Fujitsu Quaderno using dpt-rp1-py
# https://github.com/janten/dpt-rp1-py
{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.dpt-rp1-py

    # I use this program to set the mode of the device to CDC/ECM manually. See
    # https://github.com/janten/dpt-rp1-py/blob/master/docs/linux-ethernet-over-usb.md#switching-the-usb-mode-the-ethernet-over-usb
    # for an instruction.
    pkgs.picocom
  ];

  # The current PIDs.

  # ids = {
  #   uids.avahi = 991;
  #   gids.avahi = 989;
  # };

  services.avahi = {
    # enable = true;

    # Check the interface name
    allowInterfaces = [
      "usb1"
    ];
    # Only IPv6 is used by the program
    ipv6 = true;
    nssmdns6 = true;
  };
}
