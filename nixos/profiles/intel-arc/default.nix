# Based on https://github.com/VTimofeenko/monorepo-machine-config/blob/4c1f85c700c45a5d3a8a38956194d2c97753b8ba/nixosConfigurations/neon/configuration/hw-acceleration.nix#L24
#
# Also add inputs.nixos-hardware.nixosModules.common-gpu-intel to the module
# list in flake.nix
{ pkgs, ... }:
{
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-ocl
      # nixos-unstable
      vpl-gpu-rt
      intel-compute-runtime
      intel-vaapi-driver
    ];
  };

  boot.kernelParams = [
    # Check the ID by running `lspci -k | grep -EA3 'VGA|3D|Display'`
    "i915.force_probe=6021"
    "i915.enable_guc=3"
  ];

  environment.sessionVariables = {
    VDPAU_DRIVER = "va_gl";
    LIBVA_DRIVER_NAME = "iHD";
  };
  hardware.intelgpu.driver = "xe";

  # Use the latest kernel for the intel driver that supports ZFS
  boot.kernelPackages = pkgs.linuxPackages_latest;

  environment.systemPackages = with pkgs; [
    libva-utils
    intel-gpu-tools
  ];
}
