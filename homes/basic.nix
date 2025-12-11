{ config, lib, pkgs, ... }:
{
  programs = {
    nix-index.enable = true;
    nix-index.enableZshIntegration = config.programs.nix-index.enable;
    password-store.enable = true;

    nh = {
      enable = lib.mkDefault true;
      # clean.enable = true;
      flake = "${config.home.homeDirectory}/build/nix-config";
    };

    nix-your-shell = {
      enable = true;
    };
  };

  home.packages = with pkgs; [
    # Nix
    nix-prefetch-git
    nix-output-monitor

    # Development
    gh
    difftastic
    duckdb
    hyperfine
    just
    tailspin

    # Media
    git-annex

    # System
    btop
    dua
    duf

    # Net
    xh

    # Net
    openssl
  ];

  services = {
    recoll.enable = true;
    syncthing.enable = true;
  };
}
