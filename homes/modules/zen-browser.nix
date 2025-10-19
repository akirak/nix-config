{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.programs.zen-browser;
in
{
  config.programs.zen-browser = lib.mkIf cfg.enable {
    # Use the stable version instead of the default beta.
    package = pkgs.zen-browser;

    # Common policies from
    # https://github.com/0xc000022070/zen-browser-flake?tab=readme-ov-file#some-common-policies.
    # See https://mozilla.github.io/policy-templates/ for options.
    policies = {
      AutofillAddressEnabled = true;
      AutofillCreditCardEnabled = false;
      DisableAppUpdate = true;
      DisableFeedbackCommands = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableTelemetry = true;
      DontCheckDefaultBrowser = true;
      NoDefaultBookmarks = true;
      OfferToSaveLogins = false;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
    };

    # TODO: Configure profiles

    # profiles.default = {
    # };
  };
}
