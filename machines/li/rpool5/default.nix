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

  virtualisation.containers.containersConf.settings = {
    engine.env = [
      "TMPDIR=/var/tmp"
    ];
  };
}
