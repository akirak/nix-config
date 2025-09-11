/*
Default integration with home-manager

You also have to import home-manager.nixosModules.home-manager
*/
{
  homeUser,
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../nixpkgs/channels.nix
  ];

  users.defaultUserShell =
    if config.programs.zsh.enable
    then pkgs.zsh
    else pkgs.bash;

  programs.zsh.enable = true;

  users.users.${homeUser}.extraGroups =
    (lib.optional config.virtualisation.docker.enable "docker")
    ++ (lib.optionals config.virtualisation.virtualbox.host.enable [
      "vboxusers"
      "vboxsf"
    ]);

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";

    users.${homeUser} = {
      imports = [
        ../../../homes/core.nix
      ];

      # Conflicts with the NixOS setting
      programs.nh.enable = false;

      programs.nixos-rebuild-and-notify.enable = true;

      home.stateVersion = lib.mkDefault config.system.stateVersion;
    };
  };
}
