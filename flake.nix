{
  nixConfig.flake-registry = "https://raw.githubusercontent.com/akirak/flake-pins/master/registry.json";

  inputs = {
    # The following inputs are taken from the registry:
    # * stable (latest stable of nixpkgs)
    # * home-manager
    # * pre-commit-hooks
    # * flake-utils
    utils.url = "flake-utils";
    pre-commit-hooks.url = "pre-commit-hooks";
    nixpkgs.url = "stable";
    unstable.url = "unstable";

    flake-utils-plus.url = "github:gytis-ivaskevicius/flake-utils-plus";
    nix-filter.url = "github:numtide/nix-filter";

    # Switch to a private profile by overriding this input
    site = {
      url = "git+https://git.sr.ht/~akirak/default-host";
      flake = false;
    };

    # NixOS modules
    impermanence.url = "github:nix-community/impermanence";
    # nixos-hardware.url = "github:nixos/nixos-hardware";
    # agenix.url = "github:ryantm/agenix";
    # agenix.inputs.nixpkgs.follows = "latest";

    # Emacs
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

    # zsh plugins
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

    # other packages
    epubinfo.url = "github:akirak/epubinfo";
    squasher.url = "github:akirak/squasher";

    # pre-commit
    flake-no-path = {
      url = "github:akirak/flake-no-path";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "utils";
      inputs.pre-commit-hooks.follows = "pre-commit-hooks";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils-plus,
    utils,
    home-manager,
    impermanence,
    ...
  } @ inputs: let
    mkApp = utils.lib.mkApp;
    homeProfiles = import ./home {inherit (nixpkgs) lib;};
    resolveHomeModules = config:
      config
      // {
        homeModules =
          nixpkgs.lib.attrVals config.homeModules homeProfiles
          ++ (config.extraHomeModules or []);
      };
    importSite = src: resolveHomeModules (import src);
    site = importSite inputs.site;

    inherit (inputs.home-manager.lib) homeManagerConfiguration;

    emacsOverlay = import ./emacs/overlay.nix {
      inherit inputs;
    };
  in
    flake-utils-plus.lib.mkFlake {
      inherit self inputs;

      supportedSystems = ["x86_64-linux"];

      channelsConfig = {
        allowBroken = false;
        allowUnfreePredicate = pkg:
          builtins.elem (nixpkgs.lib.getName pkg) [
            # Explicitly select unfree packages.
            "wpsoffice"
            "steam-run"
            "steam-original"
            "symbola"
          ];
      };

      sharedOverlays = [
        (import ./pkgs/overlay.nix)
        inputs.flake-no-path.overlay
        (_: prev: {
          inherit (inputs.epubinfo.packages.${prev.system}) epubinfo;
        })
        (_: prev: {
          inherit (inputs.squasher.packages.${prev.system}) squasher;
        })
        emacsOverlay
        # zsh plugins used in the home-managerconfiguration
        (_: _:
          import ./pkgs/zsh-plugins.nix {
            inherit inputs;
            inherit (nixpkgs) lib;
          })
      ];

      # Nixpkgs flake reference to be used in the configuration.
      # Autogenerated from `inputs` by default.
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
            home-manager.useGlobalPkgs = true;
            environment.etc."nix/inputs/nixpkgs".source = inputs.unstable.outPath;
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

        modules = [
          ({site, ...}: {
            boot.isContainer = true;
            networking.useDHCP = false;
            networking.firewall = {
              enable = true;
              allowedTCPPorts = [];
            };

            services.openssh = {
              enable = true;
            };

            system.stateVersion = "22.11";
            home-manager.users.${site.username}.home.stateVersion = "22.11";
          })

          ./nixos/profiles/default-user.nix

          ./nixos/base.nix
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

            networking.firewall = {
              enable = true;
            };

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

            system.stateVersion = "22.11";
          }

          ({site, ...}: {
            home-manager.users.${site.username}.home.stateVersion = "22.11";
          })

          ./nixos/profiles/default-user.nix

          ./nixos/desktop.nix
          # ./nixos/xmonad.nix
          ./nixos/river.nix

          # Optional toy environment for experimenting with services
          # ./nixos/toy.nix

          ./nixos/frontend.nix
          ./nixos/development.nix
          ./nixos/profiles/docker.nix
          ./nixos/profiles/tailscale.nix
          # ./nixos/profiles/fcitx.nix

          # ./nixos/profiles/android.nix
        ];
      };

      #############################
      ### flake outputs builder ###
      #############################

      outputsBuilder = channels: let
        inherit (channels.nixpkgs) emacs-config emacsSandboxed;
      in {
        packages =
          {
            tryout-emacs = emacsSandboxed {
              name = "tryout-emacs";
              nativeCompileAheadDefault = false;
              automaticNativeCompile = false;
              enableOpinionatedSettings = false;
              extraFeatures = [];
              protectHome = false;
              shareNet = false;
              inheritPath = false;
            };

            inherit (channels.nixpkgs) readability-cli;

            inherit emacs-config;

            test-emacs-config = channels.nixpkgs.callPackage ./emacs/tests {};

            update-elisp = channels.nixpkgs.writeShellScriptBin "update-elisp" ''
              nix flake lock --update-input melpa --update-input gnu-elpa
              cd emacs/lock
              bash ./update.bash "$@"
            '';

            wordnet-sqlite = channels.nixpkgs.wordnet-sqlite;

            emacs-installer =
              channels.nixpkgs.callPackage
              ./pkgs/development/emacs-sandboxed/multi-installer.nix {}
              {inherit (site) siteConfigDir nixConfigDir;} (site.emacsProfiles or {});
          }
          // (builtins.mapAttrs (_: emacsSandboxed) (site.emacsProfiles or {}));

        apps = emacs-config.makeApps {
          lockDirName = "emacs/lock";
        };

        homeConfigurations = {
          ${site.username + "@" + site.hostName} = homeManagerConfiguration {
            # unfree must be turned on for wpsoffice
            pkgs = channels.unstable;
            extraSpecialArgs = {
              inherit site;
            };
            modules =
              [
                ./home/modules/crostini.nix
                {
                  home = {
                    inherit (site) username;
                    homeDirectory = "/home/${site.username}";
                    stateVersion = "22.11";
                  };
                }
                ./home/profiles/update.nix
              ]
              ++ site.homeModules;
          };
        };

        # Set up a pre-commit hook by running `nix develop`.
        devShells = {
          default = channels.nixpkgs.mkShell {
            inherit
              (inputs.pre-commit-hooks.lib.${channels.nixpkgs.system}.run {
                src = ./.;
                hooks = import ./hooks.nix {
                  pkgs = channels.nixpkgs;
                  emacsBinaryPackage = "emacs-config.emacs";
                };
              })
              shellHook
              ;
          };

          # Add global devShells for scaffolding new projects

          pnpm = channels.nixpkgs.mkShell {
            buildInputs = [
              channels.unstable.nodejs_latest
              channels.unstable.nodePackages.pnpm
            ];
          };

          yarn = channels.nixpkgs.mkShell {
            buildInputs = [
              channels.unstable.nodejs
              channels.unstable.yarn
            ];
          };

          npm = channels.nixpkgs.mkShell {
            buildInputs = [
              channels.unstable.nodejs_latest
            ];
          };

          elixir = channels.nixpkgs.mkShell {
            buildInputs = [
              channels.unstable.elixir
            ];
          };
        };
      };

      #########################################################
      ### All other properties are passed down to the flake ###
      #########################################################

      # checks.x86_64-linux.someCheck = pkgs.hello;
      # packages.x86_64-linux.somePackage = pkgs.hello;

      overlay =
        nixpkgs.lib.composeExtensions
        (import ./pkgs/overlay.nix)
        emacsOverlay;

      templates = {
        site = {
          description = "Configuration for home-manager and Emacs";
          path = "${inputs.site}";
        };
      };

      # abc = 132;
    };
}
