# 天宇 (Tiān Yǔ): NixOS guest on WSL 2 on laptop
{ inputs, ... }:
let
  channel = inputs.unstable;
in
{
  flake = {
    nixosConfigurations.tianyu = channel.lib.nixosSystem {
      system = "x86_64-linux";

      specialArgs = {
        hostPubkey = null;
        homeUser = "nixos";
      };

      modules = [
        inputs.home-manager-unstable.nixosModules.home-manager
        inputs.self.nixosModules.twistHomeModule
        inputs.self.nixosModules.homeInputs
        inputs.self.nixosModules.default
        inputs.nixos-wsl.nixosModules.wsl
        ./.
        {
          networking.hostName = "tianyu";
          wsl.enable = true;
        }
      ];
    };
  };
}
