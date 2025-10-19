{ inputs, ... }:
{
  flake = {
    nixosModules = {
      homeInputs = {
        imports = [
          ({homeUser, ...}: {
            home-manager.users.${homeUser} = {
              imports = [ inputs.zen-browser.homeModules.default ];
            };
          })
        ];
      };
    };
  };
}
