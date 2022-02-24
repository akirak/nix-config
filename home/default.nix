{ lib }:
with builtins;
let
  moduleDir = ./profiles;

  profiles = lib.pipe (readDir moduleDir) [
    attrNames
    (filter (name: name != "default.nix"))
    (map (name: {
      name = lib.removeSuffix ".nix" name;
      value = moduleDir + "/${name}";
    }))
    listToAttrs
  ];

  suites = lib.mapAttrs (_: imports: { inherit imports; }) (rec {
    base = [
      ./profiles/core.nix
      ./profiles/zsh.nix
      ./profiles/gpg.nix
    ];
    desktop = base ++ [
      ./profiles/development.nix
      ./profiles/graphical.nix
      ./profiles/git-annex.nix
      ./profiles/emacs
      ./profiles/reader.nix
    ];
    xmonad = desktop ++ [
      ./profiles/wm/xmonad
    ];
    personal = [
      ./profiles/dropbox.nix
    ];
  });
in
profiles // suites
