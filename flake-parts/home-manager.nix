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

    homeConfigurations = (
      builtins.listToAttrs
        (builtins.map
          # Build the minimal home-manager configuration
          (system: lib.nameValuePair "${system}-default"
            (inputs.home-manager-unstable.lib.homeManagerConfiguration {
              pkgs = import inputs.unstable {
                inherit system;
                overlays = [ inputs.self.overlays.default ];
                config.allowUnfree = true;
              };

              modules = [
                {
                  home.username = lib.mkDefault "akirakomamura";
                  home.stateVersion = lib.mkDefault "25.05";
                }
                inputs.self.homeModules.default
              ];
            })
          )

          [
            "x86_64-linux"
            "aarch64-darwin"
          ] )
    ) // {
      # Examples
      x86_64-linux-extra = inputs.self.homeConfigurations.x86_64-linux-default.extendModules {
        modules = [
          {
            home.username = "anotherUser";
            programs.gpg.enable = true;
            programs.emacs-twist = {
              enable = true;
              settings = {
                extraFeatures = [
                  "Org"
                  "Emacs__Lisp"
                  "Emacs"
                  "MCP"
                ];
              };
            };
          }
        ];
      };

    };
  };
}
