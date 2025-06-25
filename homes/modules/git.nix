{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;

  cfg = config.programs.git;

  makeGitConfig =
    {
      userName,
      userEmail,
      githubUser,
      signingKey,
    }:
    pkgs.writeText "config" (
      ''
        [user]
          name = "${userName}"
          email = "${userEmail}"
          ${lib.optionalString (signingKey != null) ''
            signingKey = "${signingKey}"
          ''}
      ''
      + lib.optionalString (githubUser != null) ''
        [github]
          user = "${githubUser}"
      ''
    );

  defaultIdentity = {
    email = "akira.komamura@gmail.com";
    fullName = "Akira Komamura";
    githubUser = "akirak";
    signingKey = "5B3390B01C01D3E";
    conditions = [
      "hasconfig:remote.*.url:git@github.com:akirak/**"
      "hasconfig:remote.*.url:git@github.com:emacs-twist/**"
      "hasconfig:remote.*.url:git@git.sr.ht:~akirak/**"
      "hasconfig:remote.*.url:https://github.com/akirak/**"
      "hasconfig:remote.*.url:https://github.com/emacs-twist/**"
      "hasconfig:remote.*.url:https://git.sr.ht/~akirak/**"
      "gitdir:~/work2/foss/"
      "gitdir:~/work2/learning/"
      "gitdir:~/work2/personal/"
      "gitdir:~/work2/prototypes/"
      "gitdir:/assets/"
      "gitdir:/git-annex/"
    ];
  };

  identityType = types.submodule {
    options = {
      email = mkOption {
        type = types.str;
        description = lib.mdDoc "E-mail address of the user";
      };
      fullName = mkOption {
        type = types.str;
        description = lib.mdDoc "Full name of the user";
      };
      githubUser = mkOption {
        type = types.nullOr types.str;
        description = lib.mdDoc "GitHub login of the user";
        default = null;
      };
      signingKey = mkOption {
        type = types.nullOr types.str;
        description = lib.mdDoc "GPG signing key";
        default = null;
      };
      conditions = mkOption {
        type = types.listOf types.str;
        description = lib.mdDoc "List of include conditions";
      };
    };
  };
in
{
  options.programs.git = {
    defaultIdentity = mkOption {
      type = types.nullOr identityType;
      description = lib.mdDoc "Default identity";
      default = defaultIdentity;
    };

    extraIdentities = mkOption {
      type = types.listOf identityType;
      description = lib.mdDoc "Extra list of identities";
      default = [ ];
    };
  };

  config = {
    programs.git = lib.mkIf cfg.enable {
      signing.format = lib.mkForce "openpgp";

      extraConfig = {
        pull.rebase = true;

        merge.conflictstyle = "diff3";

        "url \"git@github.com:\"".pushInsteadOf = "https://github.com/";
        "url \"git@git.sr.ht:\"".pushInsteadOf = "https://git.sr.ht/";

        core.autocrlf = "input";

        # Only on WSL
        # core.fileMode = false;

        # Increase the size of post buffers to prevent hung ups of git-push.
        # https://stackoverflow.com/questions/6842687/the-remote-end-hung-up-unexpectedly-while-git-cloning#6849424
        http.postBuffer = "524288000";
      };

      ignores = [
        ".direnv"
        "result"
        "result-*"
        "#*"
        ".git-bak*"
        "*.local"
        "*.local.*"
        ".aider*"
        # Non-standard
        "!.aider.conf.yml"
        "!.aiderignore"
      ];

      includes = lib.pipe ([ cfg.defaultIdentity ] ++ cfg.extraIdentities) [
        (builtins.filter (v: v != null))
        (builtins.map (
          {
            email,
            fullName,
            githubUser,
            signingKey,
            conditions,
          }:
          let
            configFile = makeGitConfig {
              inherit githubUser signingKey;
              userName = fullName;
              userEmail = email;
            };
          in
          builtins.map (condition: {
            path = configFile;
            inherit condition;
          }) conditions
        ))
        lib.flatten
      ];
    };
  };
}
