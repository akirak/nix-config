{
  inputs = {
    # Should be updated from flake-pins: <https://github.com/akirak/flake-pins>
    utils.url = "github:numtide/flake-utils";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    stable.url = "github:NixOS/nixpkgs/nixos-22.11";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-filter.url = "github:numtide/nix-filter";

    flake-pins = {
      url = "github:akirak/flake-pins";
      flake = false;
    };

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

    archiver.url = "github:emacs-twist/twist-archiver";

    # pre-commit
    flake-no-path = {
      url = "github:akirak/flake-no-path";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "utils";
      inputs.pre-commit-hooks.follows = "pre-commit-hooks";
    };

    my-overlay.url = "github:akirak/nixpkgs-overlay";
  };

  nixConfig = {
    extra-substituters = [
      "https://akirak.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "akirak.cachix.org-1:WJrEMdV1dYyALkOdp/kAECVZ6nAODY5URN05ITFHC+M="
    ];
  };

  outputs = {
    self,
    nixpkgs,
    flake-parts,
    utils,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];

      imports = [
        inputs.flake-parts.flakeModules.easyOverlay
      ];

      flake = {
        homeModules.twist = {
          imports = [
            inputs.twist.homeModules.emacs-twist
            (import ./emacs/home-module.nix self.packages)
          ];
        };
      };

      perSystem = {
        config,
        system,
        pkgs,
        final,
        ...
      }: let
        inherit (pkgs) lib;
        inherit (final) emacs-config;
        inherit (builtins) substring;
        profiles = import ./emacs/profiles.nix {inherit lib;} emacs-config;
      in {
        overlayAttrs =
          {
            coq = inputs.unstable.legacyPackages.${final.system}.coq;
            coq-lsp = inputs.unstable.legacyPackages.${final.system}.coqPackages.coq-lsp;
            flake-no-path = inputs.flake-no-path.defaultPackage.${system};
          }
          // (
            inputs.my-overlay.overlays.default final pkgs
          )
          // (
            import ./emacs/overlay.nix {
              inherit inputs;
              configurationRevision = "${substring 0 8 self.lastModifiedDate}.${
                if self ? rev
                then substring 0 7 self.rev
                else "dirty"
              }";
            }
            final
            pkgs
          );

        packages =
          {
            inherit emacs-config;

            # test-emacs-config = pkgs.callPackage ./emacs/tests {};

            update-elisp-lock = pkgs.writeShellApplication {
              name = "update-elisp-lock";
              runtimeInputs = [
                pkgs.deno
              ];
              text = ''
                cd emacs/lock
                deno run --allow-read --allow-run ${scripts/update-elisp-lock.ts}
              '';
            };

            build-packages = pkgs.writeShellApplication {
              name = "build-packages";
              runtimeInputs = [
                pkgs.nix-eval-jobs
                pkgs.jq
              ];
              text = ''
                system=$(nix eval --expr builtins.currentSystem --impure --raw)
                flake="path:$(readlink -f "$PWD")#packages.$system.emacs-config.elispPackages"
                nix-eval-jobs \
                    --gc-roots-dir gcroot \
                    --flake "$flake" \
                    | while read -r line; do
                    out=$(jq -r .outputs.out <<<"$line")
                    if [[ $(nix path-info "$out" --json --store https://akirak.cachix.org \
                       2> /dev/null \
                       | jq '.[0].valid') = false ]]
                    then
                      drv=$(jq -r .drvPath <<<"$line")
                      echo "Building $drv"
                      time nix build "$drv" --no-link --print-build-logs
                    else
                      echo "$out is already built, skipping"
                    fi
                done
              '';
            };
          }
          // (
            builtins.mapAttrs (name: emacs-env:
              emacs-env
              // {
                wrappers = lib.optionalAttrs pkgs.stdenv.isLinux {
                  fuse-overlayfs =
                    pkgs.callPackage ./nix/overlayfsWrapper.nix {}
                    "emacs-${name}"
                    emacs-env;
                };

                archive-builder =
                  (inputs.archiver.overlays.default final pkgs).makeEmacsTwistArchive
                  {
                    name = "build-emacs-${name}-archive";
                    earlyInitFile = ./emacs/early-init.el;
                    narName = "emacs-profile-${name}.nar";
                    outName = "emacs-profile-${name}-${
                      builtins.substring 0 8 (inputs.self.lastModifiedDate)
                    }-${system}.tar.zstd";
                  }
                  emacs-env;
              })
            profiles
          );

        apps = emacs-config.makeApps {
          lockDirName = "emacs/lock";
        };

        # Set up a pre-commit hook by running `nix develop`.
        devShells = {
          default = pkgs.mkShell {
            inherit
              (inputs.pre-commit-hooks.lib.${system}.run {
                src = ./.;
                hooks = import ./hooks.nix {
                  pkgs = final;
                };
              })
              shellHook
              ;
          };
        };
      };
    };
}
