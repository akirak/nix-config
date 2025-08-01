{ inputs, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  perSystem = _: {
    treefmt = {
      projectRootFile = "README.org";
      programs = {
        # Previously alejandra had been used for formatting Nix, and I don't want to
        # reformat existing files until its' necessary. Thus I will disable
        # formatting checks on Nix code.

        # nixfmt-rfc-style.enable = true;

        deadnix.enable = true;
        shellcheck.enable = true;
        yamlfmt.enable = true;
      };

      settings.excludes = [
        "*.age"
        "*.pub"
        "*.org"
      ];

      settings.formatter = {
        shellcheck.excludes = [ ".envrc" ];
      };
    } ;
  };
}
