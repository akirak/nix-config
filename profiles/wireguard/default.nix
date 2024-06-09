# Based on https://uint.one/posts/configuring-wireguard-using-systemd-networkd-on-nixos/
{ config, lib, ... }:
let
  inherit (config.networking) hostName;

  hostSettings = import ./lib/get-host.nix { inherit lib; } hostName;

  inherit (hostSettings) groups;

  groupToPeers = (
    {
      hosts,
      publicKey,
      subnet,
      suffix,
      type,
      ...
    }:

    let
      peerHosts =
        if type == "server" then
          hosts
        else if type == "client" then
          # There should be no client-to-client connection.
          builtins.filter (peer: peer.type == "server") hosts
        else
          abort "Unsupport wireguard host type ${type} for host ${hostName}";
    in
    builtins.map (peer: {
      inherit publicKey;
      allowedIPs = [ subnet ];
      endpoint = "${peer.hostName}${suffix}:51820";
      persistentKeepalive = 25;
    }) peerHosts
  );

  peers = lib.pipe groups [
    (builtins.map groupToPeers)
    lib.flatten
  ];

  soleGroup =
    if builtins.length groups == 1 then
      builtins.head groups
    else
      abort "Multiple groups are not supported for now (host ${hostName})";

  isServer = soleGroup.type == "server";
in
{
  imports = [ ../agenix ];

  age.secrets = {
    "wg0.key" = {
      rekeyFile = ./secrets/wg0-${hostName}.age;
      path = "/etc/wg/wg0.key";
      mode = "640";
      owner = "root";
      group = "systemd-network";
    };
  };

  networking.firewall = {
    allowedUDPPorts = [ config.networking.wireguard.interfaces.wg0.listenPort ];
  };

  networking.wireguard.interfaces.wg0 = {
    ips = builtins.map ({ ipAddress, ... }: ipAddress) groups;

    listenPort = 51820;

    privateKeyFile = config.age.secrets."wg0.key".path;

    inherit peers;
  };

  networking.nat = lib.mkIf isServer {
    enable = true;
    inherit (hostSettings) externalInterface;
    internalInterfaces = [ "wg0" ];
  };
}
