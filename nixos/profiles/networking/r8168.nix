{
  pkgs,
  config,
  ...
}:
{
  # At present, wired interface does not work even with this kernel module due
  # to a common "ucsi_acpi usbc000:00: ppm init failed" error. This issue may be
  # fixed at some point, but I am not sure.
  boot.extraModulePackages = [
    (config.boot.kernelPackages.r8168.overrideAttrs (
      _: super: rec {
        version = "8.054.00";
        src = pkgs.fetchFromGitHub {
          owner = "mtorromeo";
          repo = "r8168";
          rev = version;
          sha256 = "sha256-KyycAe+NBmyDDH/XkAM4PpGvXI5J1CuMW4VuHcOm0UQ=";
        };
        meta = super.meta // {
          broken = false;
        };
      }
    ))
  ];
  boot.blacklistedKernelModules = [ "r8169" ];
}
