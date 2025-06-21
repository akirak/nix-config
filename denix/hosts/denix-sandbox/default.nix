{delib, ...}:
delib.host {
  name = "denix-sandbox";
  type = "server";

  myconfig = {
    microvm = {
      enable = true;
      hypervisor = "cloud-hypervisor";
    };
  };
}
