{ pkgs, lib, ... }:
let
  port = 11007;
in
{
  systemd.services.context7-mcp = {
    description = "MCP Server for Context7";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${lib.getExe pkgs.mcp-servers.context7-mcp} --transport http --port ${builtins.toString port}";

      # Sandboxing options
      DynamicUser = true;
      NoNewPrivileges = true;
      PrivateTmp = true;
      PrivateDevices = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunables = true;
      ProtectControlGroups = true;
      RestrictSUIDSGID = true;

      # Network access (needed for SSE)
      IPAddressDeny = "any";
      IPAddressAllow = "localhost";
    };
  };
}
