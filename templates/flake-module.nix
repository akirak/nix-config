{
  flake = {
    # Templates can be defined only once
    templates = {
      nixos-wsl = {
        path = ./nixos-wsl;
        description = "An example configuration flake for NixOS-WSL";
      };
    };
  };
}
