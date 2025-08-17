{nixos-hardware}: {...}: {
  imports = [
    (nixos-hardware.outPath + "/common/pc/laptop")
    (nixos-hardware.outPath + "/common/gpu/intel")
    ../../../profiles/networking/r8168.nix
    ./wireless.nix
    ./acpi_call.nix
  ];

  # I don't know if this parameter is necessary.
  boot.kernelParams = ["nouveau.modeset=0"];

  # boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_0;

  boot.blacklistedKernelModules = [ "r8169" ];
}
