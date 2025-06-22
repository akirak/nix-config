{delib, ...}:
delib.host {
  name = "denix-sandbox";
  type = "server";
  useHomeManagerModule = false;

  myconfig = {
    microvm = {
      enable = true;
      hypervisor = "cloud-hypervisor";
    };
  };
}
