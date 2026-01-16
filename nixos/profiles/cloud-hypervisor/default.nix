{ homeUser, pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.cloud-hypervisor
  ];

  # Required if you want to enable TAP networks
  # security.wrappers.cloud-hypervisor = {
  #   source = lib.getExe pkgs.cloud-hypervisor;
  #   capabilities = "cap_net_admin+ep";
  #   owner = "root";
  #   group = "root";
  # };

  users.users.${homeUser}.extraGroups = [
    # Needed to create a tap network with microvm.nix
    "kvm"
    ];
}
