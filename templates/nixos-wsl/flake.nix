{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";

    emacs-config = {
      url = "github:akirak/emacs-config/develop";
      inputs.flake-pins.follows = "flake-pins";
    };
    flake-pins.url = "github:akirak/flake-pins";
    homelab.url = "github:akirak/homelab";
  };

  outputs = {
    nixpkgs,
    flake-parts,
    ...
  } @ inputs: flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
      ];

      perSystem = {pkgs, ...}: {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.just
          ];
        };
      };

      flake = {
        nixosConfigurations = {
          wsl-private = inputs.homelab.lib.mkSystem (throw "Set the host name") {
            system = "x86_64-linux";
            self' = inputs.self;
            channel = nixpkgs;
            specialArgs = {
              homeUser = throw "Set the user name";
              inherit (inputs) emacs-config;
            };
            extraModules = [
              # Mandatory settings for NixOS-WSL
              (inputs.nixos-wsl.outPath + "/modules")
              ({homeUser, ...}: {
                wsl.enable = true;
                wsl.defaultUser = homeUser;
                system.stateVersion = "23.11";
                time.timeZone = throw "Set your time zone";
              })

              inputs.home-manager.nixosModules.home-manager
              inputs.homelab.nixosModules.hmProfile

              # Add profiles as needed
              (inputs.homelab.outPath + "/profiles/nix")
              (inputs.homelab.outPath + "/profiles/locale")
              # (inputs.homelab.outPath + "/profiles/docker/rootless.nix")

              # My custom settings
              ({homeUser, ...}: {
                home-manager.users.${homeUser} = {
                  imports = [
                    (inputs.homelab.outPath + "/homes/basic.nix")
                    (inputs.homelab.outPath + "/homes/wsl.nix")
                  ];

                  home.username = homeUser;
                  home.homeDirectory = "/home/${homeUser}";
                  home.stateVersion = "23.11";

                  programs.git.extraIdentities = [
                    {
                      email = throw "E-mail address";
                      fullName = throw "Full Name";
                      conditions = [
                        (throw "Please set conditions")
                        "hasconfig:remote.*.url:git@YOURORG.com:XXX/**"
                        "hasconfig:remote.*.url:https://YOURORG.com/XXX/**"
                        "gitdir:~/work2/XXX/"
                      ];
                    }
                  ];

                  programs.emacs-twist = {
                    enable = true;
                    serviceIntegration.enable = true;
                    settings = {
                      extraFeatures = [
                      ];
                    };
                  };
                };
              })
            ];
          };
        };
      };
    };
}
