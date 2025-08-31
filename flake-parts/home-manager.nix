{ inputs, lib, ... }:
{
  flake = {
    # Export a reusable Home Manager module so external users can
    # import and extend it from their own flakes/configs.
    homeModules = {
      default = { pkgs, ... }: {
        imports = [
          ../homes/basic.nix
          ../homes/code.nix

          # Emacs (Twist)
          inputs.emacs-config.homeModules.twist
          { programs.emacs-twist.enable = true; }
        ];

        # Keep it cross-platform; resolve platform with pkgs.
        _module.args = { inherit pkgs; };
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

    # Helper to construct a Home Manager configuration with optional
    # extra modules supplied by the caller. Supports lib.extendModules
    # to extend the base home module.
    lib.mkHome =
      {
        channel ? inputs.unstable,
        system ? builtins.currentSystem,
        username ? "akirakomamura",
        stateVersion ? "25.05",
        extraModules ? [ ],
        # If provided, uses lib.extendModules to extend the base module.
        # Example: extend = { modules = [ ./my-extra.nix ]; specialArgs = { foo = "bar"; }; }
        extend ? null,
      }:
      let
        pkgs = import channel {
          inherit system;
          overlays = [ inputs.self.overlays.default ];
        };
        baseModule =
          if extend == null then inputs.self.homeModules.default
          else lib.extendModules extend inputs.self.homeModules.default;
      in
      inputs.home-manager-unstable.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          {
            home = {
              inherit username stateVersion;
              homeDirectory = if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";
            };
          }
          baseModule
        ] ++ extraModules;
      };

    # Convenience wrapper to extend the exported home module with
    # lib.extendModules from outside this flake.
    lib.extendHomeModule = extendArgs:
      lib.extendModules extendArgs inputs.self.homeModules.default;

    # Cross-platform Home Manager configuration (Linux/macOS)
    # Can be extended externally by calling lib.mkHome with extraModules
    # or by importing self.homeModules.default alongside your own modules.
    homeConfigurations = let
      username = "akirakomamura";
    in {
      ${username} = inputs.self.lib.mkHome {
        inherit username;
        # Example to extend from outside:
        # extraModules = [ ./my-extra-home.nix ];
      };
    };
  };
}
