{ inputs, ... }:
let
  channel = inputs.unstable;
in
{
  flake = {
    nixosConfigurations.hui = channel.lib.nixosSystem {
      system = "x86_64-linux";

      specialArgs = {
        homeUser = "akirakomamura";
        hostPubkey = null;
        inherit (inputs) emacs-config;
      };

      modules = [
        inputs.home-manager-unstable.nixosModules.home-manager
        inputs.self.nixosModules.asus-br1100
        inputs.self.nixosModules.twistHomeModule
        inputs.self.nixosModules.homeInputs
        inputs.self.nixosModules.default
        ./.
        {
          networking.hostName = "hui";
        }
      ];
    };
  };
}
