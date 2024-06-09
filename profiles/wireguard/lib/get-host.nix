let
  externalInterfaces = {
    yang = "enp1s0";
    li = "enp0s31f6";
  };

  peerGroups = [
    {
      suffix = ".home";
      subnet = "10.10.85.0/24";
      hosts = [
        {
          type = "server";
          hostName = "yang";
          ipAddress = "10.10.85.60";
          publicKey = "9LNggLgVeBURgNIIrod28vJIzNnm1Z4X2SbkmXPt1XQ=";
        }
        {
          type = "client";
          hostName = "li";
          ipAddress = "10.10.85.11";
          publicKey = "OWZAr0878qk5AU/zxAjl0SLaBzRfbNq1RfMGQiv3OSE=";
        }
      ];
    }
  ];

  inherit (builtins) abort filter map;
in
{ lib }:
hostName:
let
  matchTheHostName = host: host.hostName == hostName;

  matchingGroups = filter ({ hosts, ... }: builtins.any matchTheHostName hosts) peerGroups;
in
{
  externalInterface = externalInterfaces.${hostName};
  groups = map (
    group@{ hosts, ... }:
    group
    // (lib.findSingle matchTheHostName (abort "No host matching ${hostName}")
      (abort "Multiple hosts matching ${hostName}")
      hosts
    )
  ) matchingGroups;
}
