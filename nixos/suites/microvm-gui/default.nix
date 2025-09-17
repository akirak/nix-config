/*
MicroVM with GUI for rapid prototyping of a desktop environment

Based on https://github.com/astro/microvm.nix/blob/main/flake.nix
*/
{ ...}: let
  xrdpPort = 3389;
in {
  imports = [
    ../../profiles/microvm
    ../../profiles/microvm/ssh.nix
  ];

  # Set a message printed to the console before login.
  services.getty.helpLine = ''
    Connect to the RDP server using xfreerdp/wlfreerdp:

      xfreerdp /u:root /v:localhost:${builtins.toString xrdpPort}

    From this console, you can log in as "root" with an empty password.
  '';

  # login: "root", password: empty
  users.users.root.password = "";

  microvm = {
    mem = 4096;
    vcpu = 2;
  };

  nixpkgs.config.permittedInsecurePackages = [
    "xrdp-0.9.9"
  ];

  services.xserver = {
    enable = true;
  };

  services.xrdp = {
    enable = true;
    openFirewall = true;
    port = xrdpPort;
  };

  microvm.forwardPorts = [
    {
      host.port = xrdpPort;
      guest.port = xrdpPort;
    }
  ];
}
