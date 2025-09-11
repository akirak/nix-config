{...}: {
  imports = [
    ../../profiles/openssh
  ];

  networking.firewall.enable = true;
}
