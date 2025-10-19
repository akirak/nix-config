{
  inputs = {
    flake-pins.url = "github:akirak/flake-pins";

    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    stable.url = "github:NixOS/nixpkgs/nixos-25.05";

    # More frequently input to use the newer versions of packages.
    unstable-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";

    home-manager-stable.url = "github:nix-community/home-manager/release-25.05";
    home-manager-unstable.url = "github:nix-community/home-manager";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    home-manager-stable.inputs.nixpkgs.follows = "stable";
    home-manager-unstable.inputs.nixpkgs.follows = "unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    denix = {
      url = "github:yunfachi/denix";
      inputs.nixpkgs.follows = "unstable";
      inputs.home-manager.follows = "home-manager-unstable";
    };

    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "unstable";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "unstable";
    };

    impermanence.url = "github:nix-community/impermanence";

    agenix.url = "github:ryantm/agenix";
    agenix-rekey.url = "github:oddlama/agenix-rekey";
    agenix-rekey.inputs.nixpkgs.follows = "unstable";

    mcp-servers = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "unstable";
    };

    nix-ai-tools.url = "github:numtide/nix-ai-tools";

    # cachix-deploy-flake = {
    #   url = "github:cachix/cachix-deploy-flake";
    #   inputs.nixpkgs.follows = "stable";
    #   inputs.home-manager.follows = "home-manager-stable";
    #   inputs.darwin.follows = "nix-darwin";
    # };

    treefmt-nix.url = "github:numtide/treefmt-nix";

    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "unstable";
    };

    hyprland-contrib.url = "github:hyprwm/contrib";

    emacs-config = {
      url = "github:akirak/emacs-config/develop";
      inputs.twist.follows = "twist";
    };
    twist.url = "github:emacs-twist/twist.nix";

    # Just don't override the nixpkgs input so I can utilize the binary cache.
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
  };

  nixConfig = {
    extra-substituters = [
      "https://cachix.cachix.org"
      "https://hyprland.cachix.org"
      "https://akirak.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWwy4KQ/HNxht7H4SSoMckM="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "akirak.cachix.org-1:WJrEMdV1dYyALkOdp/kAECVZ6nAODY5URN05ITFHC+M="
    ];
  };

  outputs =
    {
      unstable,
      flake-parts,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./flake-parts/deploy.nix
        ./flake-parts/treefmt.nix
        ./flake-parts/agenix.nix
        ./flake-parts/installers.nix
        ./flake-parts/pkgs.nix
        ./flake-parts/emacs.nix
        ./flake-parts/nixos.nix
        ./flake-parts/home-inputs.nix
        # ./flake-parts/cachix-deploy.nix

        ./templates/flake-module.nix

        ./nixos/models/asus-br1100/flake-module.nix

        ./machines/li/flake-module.nix
        ./machines/yang/flake-module.nix
        ./machines/wang/flake-module.nix
        ./machines/shu/flake-module.nix
        ./machines/hui/flake-module.nix
        ./machines/zheng/flake-module.nix

        ./denix/flake-module.nix
      ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      perSystem =
        {
          system,
          ...
        }:
        {
          _module.args.pkgs = unstable.legacyPackages.${system};
        };
    };
}
