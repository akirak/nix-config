{ inputs, ... }:
let
  channel = inputs.unstable;
in
{
  flake = {
    nixosConfigurations.li = channel.lib.nixosSystem {
      system = "x86_64-linux";

      specialArgs = {
        homeUser = "akirakomamura";
        hostPubkey = null;
        inherit (inputs) emacs-config;
      };

      modules = [
        inputs.home-manager-unstable.nixosModules.home-manager
        inputs.nixos-hardware.nixosModules.common-gpu-intel
        inputs.self.nixosModules.twistHomeModule
        inputs.self.nixosModules.default
        ./.
        {
          networking.hostName = "li";
        }
      ];
    };
  };
}
