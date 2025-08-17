{ lib, ... }:
let
  systemSsd = "/dev/disk/by-id/ata-CT500BX500SSD1_2432E8BE667B";
  cryptBtrfs = "root";
  decryptedDevice = "/dev/mapper/${cryptBtrfs}";
in
{
  imports = [
    (import ./btrfs.nix {
      device = decryptedDevice;
    })
    ./storage1.nix
    # ./annex.nix
  ];

  boot.initrd.luks.devices.${cryptBtrfs} = {
    device = "${systemSsd}-part2";
    allowDiscards = true;
  };

  # Required for impermanence. See
  # https://github.com/nix-community/impermanence?tab=readme-ov-file#btrfs-subvolumes
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    mkdir /btrfs_tmp
    mount ${decryptedDevice} /btrfs_tmp
    if [[ -e /btrfs_tmp/root ]]; then
        mkdir -p /btrfs_tmp/old_roots
        timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
        mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
    fi

    delete_subvolume_recursively() {
        IFS=$'\n'
        for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
            delete_subvolume_recursively "/btrfs_tmp/$i"
        done
        btrfs subvolume delete "$1"
    }

    for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
        delete_subvolume_recursively "$i"
    done

    btrfs subvolume create /btrfs_tmp/root
    umount /btrfs_tmp
  '';

  fileSystems = {
    "/boot" = {
      device = "${systemSsd}-part1";
      fsType = "vfat";
      options = [
        "fmask=0137"
        "dmask=0027"
      ];
    };
  };

  services.smartd = {
    enable = true;
    devices = [
      { device = systemSsd; }
      # {
      #   device = "/dev/disk/by-id/ata-TOSHIBA_MG08ADA800E_74G0A1ZQFCXH";
      # }
      # {
      #   device = "/dev/disk/by-id/ata-TOSHIBA_MG08ADA800E_74G0A203FCXH";
      # }
    ];
  };
}
