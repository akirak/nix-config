let
  hypervisorsWith9p = [
    "qemu"
  ];

  hypervisorsWithUserNet = [
    "qemu"
    "kvmtool"
  ];
in
  {
    lib,
    delib,
    inputs,
    ...
  }:
delib.module {
  name = "microvm";

  options.microvm = with delib; {
    enable = boolOption false;

    hypervisor = strOption "qemu";
  };

  nixos.always.imports = [
    inputs.microvm.nixosModules.microvm
  ];

  nixos.ifEnabled = {cfg, ...}: {
    services.getty.autologinUser = "root";

    microvm = {
      inherit (cfg) hypervisor;
      # share the host's /nix/store if the hypervisor can do 9p
      shares = lib.optional (builtins.elem cfg.hypervisor hypervisorsWith9p) {
        tag = "ro-store";
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
      };
      interfaces = lib.optional (builtins.elem cfg.hypervisor hypervisorsWithUserNet) {
        type = "user";
        id = "qemu";
        mac = "02:00:00:01:01:01";
      };
      forwardPorts = lib.optional (cfg.hypervisor == "qemu") {
        host.port = 2222;
        guest.port = 22;
      };
    };

    services.openssh = lib.optionalAttrs (cfg.hypervisor == "qemu") {
      enable = true;
      settings.PermitRootLogin = "yes";
    };

    networking.firewall.allowedTCPPorts = lib.optional (cfg.hypervisor == "qemu") 22;
  };
}
