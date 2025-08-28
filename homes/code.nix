{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Build an interpreter-only derivation for running a package directly.
  onlySingleBin =
    drv: name:
    (pkgs.callPackage (
      { runCommand, makeWrapper }:
      runCommand name
        {
          buildInputs = [
            makeWrapper
          ];
          propagatedBuildInputs = [ drv ];
        }
        ''
          mkdir -p $out/bin
          makeWrapper ${lib.getExe' drv name} $out/bin/${name} \
            --prefix PATH : ${lib.getBin drv}/bin
        ''
    ) { });
in
{
  programs.uv.enable = true;

  home.packages =
    (with pkgs; [
      yamlfmt
      vscode-langservers-extracted # Primarily for the JSON server
      nil # Nix
      just-lsp

      ai-tools.codex
      unstable-small-unfree.aider-chat
      ai-tools.claude-code
      ai-tools.opencode
      unstable-small-unfree.gemini-cli

      serena

      # Used to run MCP servers.
      (onlySingleBin pkgs.nodejs "npx")
    ])
    ++ (lib.optional (!config.programs.uv.enable) (onlySingleBin pkgs.uv "uvx"))
    ++ (lib.optionals pkgs.stdenv.isLinux [
      # Sandbox MCP scripts
      pkgs.bubblewrap
    ]);
}
