{ inputs, lib, ... }:
{
  flake = {
    homeModules = {
      default =
        { config, pkgs, ... }:
        {
          imports = [
            ../homes/basic.nix
            ../homes/code.nix
            inputs.emacs-config.homeModules.twist
          ];

          home.homeDirectory =
            if pkgs.stdenv.isDarwin then "/Users/${config.home.username}" else "/home/${config.home.username}";
        };
    };

    nixosModules = {
      hmProfile = {
        nixpkgs.overlays = [ inputs.self.overlays.default ];
        imports = [
          # Use a home-manager channel corresponding to your OS
          # inputs.home-manager.nixosModules.home-manager
          inputs.self.nixosModules.twistHomeModule
          ../nixos/profiles/home-manager
        ];
      };
    };
  };
}
