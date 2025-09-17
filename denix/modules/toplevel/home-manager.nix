{
  delib,
  moduleSystem,
  homeManagerUser,
  config,
  constants,
  host,
  ...
}:
delib.module {
  name = "home-manager";

  options = delib.singleEnableOption (host.type == "desktop");

  myconfig.always.args.shared.homeconfig =
    if moduleSystem == "home" then config else config.home-manager.users.${homeManagerUser};

  home.ifEnabled =
    let
      inherit (constants) username;
    in
    {
      home = {
        inherit username;
        homeDirectory = "/home/${username}";
      };
    };
}
