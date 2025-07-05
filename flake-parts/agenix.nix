{ lib, inputs, ... }:
let
  inherit (inputs) self;

  hostPubkeys = lib.pipe (lib.importTOML ../machines/metadata.toml).hosts [
    (lib.filterAttrs (_: attrs: attrs ? publicKey))
    (builtins.mapAttrs (_: attrs: attrs.publicKey))
  ];
in
{
  flake = {
    agenix-rekey = inputs.agenix-rekey.configure {
      userFlake = self;
      nixosConfigurations = builtins.intersectAttrs hostPubkeys self.nixosConfigurations;
    };

    lib = {
      inherit hostPubkeys;
    };
  };

  perSystem =
    { system, pkgs, ... }:
    {
      devShells = {
        default = pkgs.mkShell {
          buildInputs = [
            pkgs.age
            pkgs.age-plugin-yubikey

            # This is not related to agenix.
            # It is just a program required for maintaining this configuration.
            pkgs.deno
          ];
          nativeBuildInputs = [ inputs.agenix-rekey.packages.${system}.default ];
        };
      };
    };
}
