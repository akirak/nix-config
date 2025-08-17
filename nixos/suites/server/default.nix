{pkgs, ...}: {
  imports = [
    ../base
  ];

  environment.systemPackages = with pkgs; [
    duf
    du-dust
    iotop
  ];
}
