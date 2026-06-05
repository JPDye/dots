{
  config,
  inputs,
  lib,
  pkgs,
  system,
  ...
}:

let
  cfg = config.dotfiles.dev.claude-code;

  # The flake ships a single wrapper binary. Claude Code keys *everything*
  # off CLAUDE_CONFIG_DIR — login (.credentials.json), account + MCP servers
  # (.claude.json), settings, skills, history, projects/ — so pointing a
  # second command at a different dir gives a fully independent setup with its
  # own account. `claude` uses the default ~/.claude; `claude2` uses ~/.claude2.
  claudePkg = inputs.claude-code.packages.${system}.default;

  claude2 = pkgs.writeShellScriptBin "claude2" ''
    export CLAUDE_CONFIG_DIR="''${CLAUDE_CONFIG_DIR:-$HOME/.claude2}"
    exec ${claudePkg}/bin/claude "$@"
  '';

  home = config.home.homeDirectory;
in
{
  options.dotfiles.dev.claude-code.enable =
    lib.mkEnableOption "Claude Code CLI with a second account (claude + claude2)"
    // {
      default = true;
    };

  config = lib.mkIf cfg.enable {
    home.packages = [
      claudePkg
      claude2
    ];

    # claude2 borrows account 1's settings, skills, agents and plugins so you
    # configure them once. These are out-of-store symlinks to the live files
    # under ~/.claude, so edits from either command are shared. Login and
    # history (.credentials.json, .claude.json, projects/) are intentionally
    # NOT linked and stay separate per account.
    home.file = {
      ".claude2/settings.json".source =
        config.lib.file.mkOutOfStoreSymlink "${home}/.claude/settings.json";
      ".claude2/skills".source = config.lib.file.mkOutOfStoreSymlink "${home}/.claude/skills";
      ".claude2/agents".source = config.lib.file.mkOutOfStoreSymlink "${home}/.claude/agents";
      ".claude2/plugins".source = config.lib.file.mkOutOfStoreSymlink "${home}/.claude/plugins";

      # Guarantee the shared dirs exist so the symlinks above never dangle.
      ".claude/skills/.keep".text = "";
      ".claude/agents/.keep".text = "";
      ".claude/plugins/.keep".text = "";
    };
  };
}
