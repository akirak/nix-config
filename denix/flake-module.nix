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

  isMicroVM = toplevel: toplevel.config.myconfig.microvm.enable;

  excludeMicroVMs = lib.filterAttrs (_: isMicroVM);

  getMicroVMRunner = name:
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
