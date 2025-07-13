{ lib, inputs, ... }:
let
  inherit (inputs) unstable;

  overlays = [
    inputs.flake-pins.overlays.default
    (_final: prev: {
      channels = lib.genAttrs [
        "hyprland-contrib"
        "fonts"
        "zsh-plugins"
      ] (name: inputs.${name}.packages.${prev.system});
      unstable = unstable.legacyPackages.${prev.system};
      # Explicit import from the small nixpkgs.
      unstable-small-unfree = import inputs.unstable-small {
        inherit (prev) system;
        config.allowUnfree = true;
      };
      # unstable-small = inputs.unstable-small.legacyPackages.${prev.system};
      mcp-servers = inputs.mcp-servers.packages.${prev.system};
      disko = inputs.disko.packages.${prev.system}.disko;
      nix-index = inputs.nix-index-database.packages.${prev.system}.nix-index-with-db;
    })
  ];
in
{
  flake = {
    overlays.default = lib.composeManyExtensions overlays;
  };
}
