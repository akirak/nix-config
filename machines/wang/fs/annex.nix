{
  boot.initrd.luks.reusePassphrases = true;

  boot.initrd.luks.devices = {
    annex3 = {
      device = "/dev/disk/by-partuuid/52d4b016-9e9c-4b1e-b830-1d817e4f25f1";
    };
    annex4 = {
      device = "/dev/disk/by-partuuid/715e32cf-5686-4e68-9b6b-b8075675e2fa";
    };
  };

  fileSystems = {
    "/git-annex/wang-annex3" = {
      device = "/dev/mapper/annex3";
      fsType = "ext4";
      options = [
        "noatime"
      ];
    };
    "/git-annex/wang-annex4" = {
      device = "/dev/mapper/annex4";
      fsType = "ext4";
      options = [
        "noatime"
      ];
    };
  };
}
