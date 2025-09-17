{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";

    my-overlay.url = "github:akirak/nixpkgs-overlay";
    emacs-config.url = "github:akirak/emacs-config/develop";
    homelab.url = "github:akirak/homelab";
  };

  nixConfig = {
    registry = "https://raw.githubusercontent.com/akirak/flake-pins/master/registry.json";
    extra-substituters = [
      "https://akirak.cachix.org"
    ];
    extra-trusted-public-keys = [
      "akirak.cachix.org-1:WJrEMdV1dYyALkOdp/kAECVZ6nAODY5URN05ITFHC+M="
    ];
  };

  outputs = {
    nixpkgs,
    flake-parts,
    home-manager,
    ...
  } @ inputs: let
    inherit (nixpkgs) lib;

    overlays = [
      (_final: prev: {
        unstable = inputs.unstable.legacyPackages.${prev.system};
        zsh-plugins = inputs.my-overlay.zsh-plugins;
      })
      inputs.my-overlay.overlays.default
    ];

    allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        # Explicitly select unfree packages.
        "symbola"
      ];

    pkgsForSystem = system:
      import nixpkgs {
        inherit system;
        inherit overlays;
        config = {
          inherit allowUnfreePredicate;
        };
      };

    systems = [
      "x86_64-linux"
    ];
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      inherit systems;

      flake = {
        homeConfigurations = {
          penguin = home-manager.lib.homeManagerConfiguration {
            pkgs = pkgsForSystem "x86_64-linux";
            extraSpecialArgs = {
              homeUser = "akirakomamura";
              inherit (inputs) emacs-config;
            };
            modules = [
              {
                home.stateVersion = "23.05";
              }
              ./home.nix
              (inputs.homelab.outPath + "/homes/core.nix")
              inputs.emacs-config.homeModules.twist
            ];
          };
        };

        checks = lib.genAttrs systems (system:
          lib.pipe inputs.self.homeConfigurations [
            (lib.filterAttrs (_: hc: hc.pkgs.system == system))
            (builtins.mapAttrs (_: hc: hc.activationPackage))
          ]);
      };
    };
}
