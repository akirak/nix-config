{
  inputs = {
    utils.url = "github:numtide/flake-utils";
    flake-utils-plus.url = "github:gytis-ivaskevicius/flake-utils-plus/v1.3.1";

    home-manager.url = "github:nix-community/home-manager";

    # Channels
    unstable.url = "nixpkgs/nixos-unstable";

    # Switch to a private profile by overriding this input
    site = {
      url = "path:./sites/default";
      flake = false;
    };

    # NixOS modules
    impermanence.url = "github:nix-community/impermanence";
    # nixos-hardware.url = "github:nixos/nixos-hardware";
    # agenix.url = "github:ryantm/agenix";
    # agenix.inputs.nixpkgs.follows = "latest";

    # Emacs
    nixpkgs-emacs.url = "github:NixOS/nixpkgs";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    org-babel.url = "github:emacs-twist/org-babel";
    twist.url = "github:emacs-twist/twist.nix";
    melpa = {
      url = "github:akirak/melpa/akirak";
      flake = false;
    };
    gnu-elpa = {
      url = "git+https://git.savannah.gnu.org/git/emacs/elpa.git?ref=main";
      flake = false;
    };
    epkgs = {
      url = "github:emacsmirror/epkgs";
      flake = false;
    };
    emacs = {
      url = "github:emacs-mirror/emacs";
      flake = false;
    };

    # zsh plugins
    zsh-enhancd = {
      url = "github:b4b4r07/enhancd";
      flake = false;
    };
    zsh-fast-syntax-highlighting = {
      url = "github:zdharma-continuum/fast-syntax-highlighting";
      flake = false;
    };
    zsh-nix-shell = {
      url = "github:chisui/zsh-nix-shell";
      flake = false;
    };
    zsh-fzy = {
      url = "github:aperezdc/zsh-fzy";
      flake = false;
    };

    # pre-commit
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "utils";
    };
    flake-no-path = {
      url = "github:akirak/flake-no-path";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "utils";
      inputs.pre-commit-hooks.follows = "pre-commit-hooks";
    };
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils-plus
    , utils
    , home-manager
    , impermanence
    , ...
    } @ inputs:
    let
      mkApp = utils.lib.mkApp;
      homeProfiles = import ./home { inherit (nixpkgs) lib; };
      resolveHomeModules = config: config // {
        homeModules =
          nixpkgs.lib.attrVals config.homeModules homeProfiles
            ++ (config.extraHomeModules or [ ]);
      };
      importSite = src: resolveHomeModules (import src);
      site = importSite inputs.site;

      makeHome = { channels, configuration }:
        inputs.home-manager.lib.homeManagerConfiguration {
          inherit (channels.nixpkgs) system;
          inherit (site) username;
          homeDirectory = "/home/${site.username}";
          stateVersion = "21.11";
          inherit configuration;
          extraSpecialArgs = {
            pkgs = channels.nixpkgs;
          };
          # Import custom home-manager modules (non-NixOSes)
          extraModules = import ./home/modules/modules.nix;
        };

      emacsOverlay = import ./emacs/overlay.nix {
        inherit inputs;
        nixpkgs = inputs.nixpkgs-emacs;
      };
    in
    flake-utils-plus.lib.mkFlake {
      inherit self inputs;

      supportedSystems = [ "x86_64-linux" ];

      channelsConfig = {
        allowBroken = false;
      };

      sharedOverlays = [
        (import ./pkgs/overlay.nix)
        inputs.flake-no-path.overlay
        emacsOverlay
        # zsh plugins used in the home-managerconfiguration
        (_: _: import ./pkgs/zsh-plugins.nix {
          inherit inputs;
          inherit (nixpkgs) lib;
        })
      ];

      # Nixpkgs flake reference to be used in the configuration.
      # Autogenerated from `inputs` by default.
      # channels.<name> = {}

      hostDefaults = {
        system = "x86_64-linux";
        channelName = "unstable";

        extraArgs = {
          # nixos/profiles/core.nix requires self parameter
          inherit self;
        };

        # Default modules to be passed to all hosts.
        modules = [
          impermanence.nixosModules.impermanence
          ./nixos/profiles/defaults.nix
          home-manager.nixosModules.home-manager
          {
            # Import custom home-manager modules (NixOS)
            config.home-manager.sharedModules = import ./home/modules/modules.nix;
          }
        ];
      };

      #############
      ### hosts ###
      #############

      hosts.container = {
        extraArgs = {
          site = importSite ./sites/container.nix;
        };

        modules =
          [
            {
              boot.isContainer = true;
              networking.useDHCP = false;
              networking.firewall = {
                enable = true;
                allowedTCPPorts = [ ];
              };

              services.openssh = {
                enable = true;
              };
            }

            ./nixos/profiles/default-user.nix

            ./nixos/base.nix
          ];
      };

      hosts.chen = {
        system = "x86_64-linux";
        channelName = "unstable";
        extraArgs = {
          site = importSite ./sites/chen;
        };

        modules = [
          {
            imports = [
              ./sites/chen/nixos/boot.nix
              ./sites/chen/nixos/hardware.nix
              ./sites/chen/nixos/xserver.nix
              ./sites/chen/nixos/filesystems.nix
              ./sites/chen/nixos/zfs.nix
              ./sites/chen/nixos/rpool
            ];

            networking.hostName = "chen";
            # Needed for the ZFS pool.
            networking.hostId = "1450b997";

            networking.firewall = { };

            networking.useDHCP = false;
            # networking.interfaces.enp0s31f6.useDHCP = true;
            # networking.interfaces.enp1s0.useDHCP = true;
            # networking.interfaces.wlp2s0.useDHCP = true;
            networking.networkmanager.enable = true;
            systemd.services.NetworkManager-wait-online.enable = true;

            services.journald.extraConfig = ''
              SystemMaxFiles=5
            '';

            virtualisation.virtualbox.host = {
              enable = true;
            };
          }

          ./nixos/profiles/default-user.nix

          ./nixos/desktop.nix
          ./nixos/development.nix
          ./nixos/xmonad.nix

          ./nixos/profiles/android.nix
        ];
      };

      hosts.li = {
        system = "x86_64-linux";
        channelName = "unstable";
        extraArgs = {
          site = importSite ./sites/li;
        };

        modules = [
          {
            imports = [
              ./sites/li/nixos/boot.nix
              ./sites/li/nixos/hardware.nix
              ./sites/li/nixos/xserver.nix
              ./sites/li/nixos/filesystems.nix
              ./sites/li/nixos/zfs.nix
              ./sites/li/nixos/rpool2
            ];

            networking.hostName = "li";
            # Needed for the ZFS pool.
            networking.hostId = "8425e349";

            networking.firewall = { };

            networking.useDHCP = false;
            # networking.interfaces.enp0s31f6.useDHCP = true;
            # networking.interfaces.wlp2s0.useDHCP = true;
            networking.networkmanager.enable = true;
            systemd.services.NetworkManager-wait-online.enable = true;

            services.journald.extraConfig = ''
              SystemMaxFiles=5
            '';

            virtualisation.virtualbox.host = {
              enable = true;
            };
          }

          ./nixos/profiles/default-user.nix

          ./nixos/desktop.nix
          ./nixos/development.nix
          ./nixos/xmonad.nix

          # ./nixos/profiles/android.nix
        ];
      };

      #############################
      ### flake outputs builder ###
      #############################

      outputsBuilder = channels:
        let
          inherit (channels.nixpkgs) emacs-config emacsSandboxed;
        in
        {
          packages = {
            tryout-emacs = emacsSandboxed {
              name = "tryout-emacs";
              enableOpinionatedSettings = false;
              extraFeatures = [ ];
              extraInitText = ''
                (require 'sanityinc-tomorrow-night-theme)
                (load-theme 'sanityinc-tomorrow-night t)
              '';
              protectHome = false;
              shareNet = false;
              inheritPath = false;
            };

            emacs-personalized = emacsSandboxed {
              name = "emacs-personalized";
              shareNet = false;
              protectHome = true;
              inheritPath = true;
              userEmacsDirectory = "$HOME/emacs";
              extraInitText = builtins.readFile ./home/profiles/emacs/extra-init.el;
              extraDirsToTryBind = [
                "$HOME/emacs"
                "$HOME/config"
                "$HOME/fleeting"
                "$HOME/org"
                "$HOME/resources"
              ];
            };

            inherit (channels.nixpkgs) emacs-reader readability-cli;

            inherit emacs-config;

            test-emacs-config = channels.nixpkgs.callPackage ./emacs/tests { };

            update-elisp = channels.nixpkgs.writeShellScriptBin "update-elisp" ''
              nix flake lock --update-input melpa --update-input gnu-elpa
              cd emacs/lock
              bash ./update.bash "$@"
            '';
          }
          //
          nixpkgs.lib.getAttrs [ "lock" "update" ] (emacs-config.admin "emacs/lock");

          homeConfigurations = {
            ${site.username + "@" + site.hostName} = makeHome {
              inherit channels;
              configuration = { config, pkgs, ... }: {
                # nixpkgs.config.allowUnfree = true;
                imports = site.homeModules;
              };
            };
          };

          # Set up a pre-commit hook by running `nix develop`.
          devShell = channels.nixpkgs.mkShell {
            inherit (inputs.pre-commit-hooks.lib.${channels.nixpkgs.system}.run {
              src = ./.;
              hooks = import ./hooks.nix {
                pkgs = channels.nixpkgs;
                emacsBinaryPackage = "emacs-config.emacs";
              };
            }) shellHook;
          };
        };

      #########################################################
      ### All other properties are passed down to the flake ###
      #########################################################

      # checks.x86_64-linux.someCheck = pkgs.hello;
      # packages.x86_64-linux.somePackage = pkgs.hello;

      overlay = nixpkgs.lib.composeExtensions
        (import ./pkgs/overlay.nix)
        emacsOverlay;

      templates = {
        site = {
          description = "A basic desktop host";
          path = ./sites/default;
        };
      };

      # abc = 132;
    };
}
