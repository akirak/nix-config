{ inputs, ... }:
{
  flake = {
    nixosModules = {
      homeInputs = {
        imports = [
          ({homeUser, ...}: {
            home-manager.users.${homeUser} = {
              imports = [
                inputs.zen-browser.homeModules.default
                inputs.xremap.homeManagerModules.default
                inputs.impermanence.homeManagerModules.default
              ];
            };
          })
        ];
      };
    };
  };
}
