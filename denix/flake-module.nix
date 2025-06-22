{ lib, inputs, ... }:
let
  inherit (inputs) denix;

  mkConfigurations =
    moduleSystem:
    denix.lib.configurations {
      inherit moduleSystem;
      homeManagerUser = "akirakomamura";

      paths = [
        ./hosts
        ./modules
        # ./rices
      ];

      specialArgs = {
        inherit inputs;
      };
    };

  isMicroVM = hostAttrs: hostAttrs.config.myconfig.microvm.enable;

  isNotMicroVM = hostAttrs: !isMicroVM hostAttrs;

  excludeMicroVMs = lib.filterAttrs (_: isNotMicroVM);

  getMicroVMRunner =
    name:
    let
      host = (mkConfigurations "nixos").${name};
    in
    host.config.microvm.runner.${host.config.myconfig.microvm.hypervisor};
in
{
  flake = {
    nixosConfigurations = excludeMicroVMs (mkConfigurations "nixos");
    homeConfigurations = mkConfigurations "home";

    packages.x86_64-linux.denix-sandbox = getMicroVMRunner "denix-sandbox";
  };
}
