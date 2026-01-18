{ lib, inputs, ... }:
let
  inherit (inputs) unstable;

  overlays = [
    inputs.flake-pins.overlays.default
    (
      _final: prev:
      let
        inherit (prev.stdenv.hostPlatform) system;
      in
      {
        channels = lib.genAttrs [
          "hyprland-contrib"
          "fonts"
          "zsh-plugins"
        ] (name: inputs.${name}.packages.${system});
        unstable = unstable.legacyPackages.${system};
        # Explicit import from the small nixpkgs.
        unstable-small-unfree = import inputs.unstable-small {
          inherit (prev) system;
          config.allowUnfree = true;
        };
        # unstable-small = inputs.unstable-small.legacyPackages.${system};
        mcp-servers = inputs.mcp-servers.packages.${system};
        ai-tools = inputs.llm-agents.packages.${system};
        disko = inputs.disko.packages.${system}.disko;
        nix-index = inputs.nix-index-database.packages.${system}.nix-index-with-db;

        zen-browser = inputs.zen-browser.packages.${system}.default;
        ranmaru = inputs.ranmaru.packages.${system}.default;
      }
    )
  ];
in
{
  flake = {
    overlays.default = lib.composeManyExtensions overlays;
  };
}
