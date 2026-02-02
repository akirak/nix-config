{ homeUser, ... }:
let
  tmpDir = "/var/tmp";
in
{
  imports = [ ./extras.nix ];

  fileSystems."/persist" = {
    device = "rpool5/safe/persist";
    fsType = "zfs";
    neededForBoot = true;
  };

  fileSystems."/home" = {
    device = "rpool5/safe/home";
    fsType = "zfs";
    # Needed because of impermanence
    neededForBoot = true;
  };

  # You will require github:nix-community/impermanence to use this
  environment.persistence."/persist" = {
    directories = [
      "/var/log"
      "/var/tmp"
      "/var/lib/nixos"
      "/var/lib/bluetooth"
      "/var/lib/livebook"
      "/var/lib/rabbitmq"
      "/etc/NetworkManager/system-connections"
    ];
  };

  home-manager.users.${homeUser} = {
    programs.zsh.sessionVariables = {
      # Affect rootless `podman pull`
      TMPDIR = tmpDir;
    };
  };
}
