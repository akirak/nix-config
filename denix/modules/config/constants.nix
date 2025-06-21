{delib, ...}:
delib.module {
  name = "constants";

  options.constants = with delib; {
    username = readOnly (strOption "akirakomamura");
    userfullname = readOnly (strOption "Akira Komamura");
    useremail = readOnly (strOption "akira.komamura@gmail.com");
  };

  myconfig.always = {cfg, ...}: {
    args.shared.constants = cfg;
  };
}
