{ inputs, ... }:
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
in
{
  flake = {
    # nixosConfigurations = mkConfigurations "nixos";
    # homeConfigurations = mkConfigurations "home";
  };
}
