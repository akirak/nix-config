{delib, ...}:
let
  stateVersion = "25.05";
in
  delib.host {
    name = "denix-sandbox";

    homeManagerSystem = "x86_64-linux";

    nixos = {
      nixpkgs.hostPlatform = "x86_64-linux";
      system.stateVersion = stateVersion;
    };

    home = {
      home.stateVersion = stateVersion;
    };
  }
