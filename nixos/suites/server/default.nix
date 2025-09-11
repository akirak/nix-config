{pkgs, ...}: {
  imports = [
    ../base
  ];

  environment.systemPackages = with pkgs; [
    duf
    du-dust
    iotop
  ];

  nix = {
    settings = {
      auto-optimise-store = true;
    };
    gc.automatic = true;
  };
}
