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

  # The flake ships a single wrapper binary. Claude Code keys *everything* off
  # CLAUDE_CONFIG_DIR: login (.credentials.json), account and MCP servers
  # (.claude.json), settings, skills, history, projects/. A second command
  # pointed at another dir therefore gets a fully independent setup with its
  # own account. `claude` uses the default ~/.claude. `claude2` uses
  # ~/.claude2.
  claudePkg = inputs.claude-code.packages.${system}.default;

  claude2 = pkgs.writeShellScriptBin "claude2" ''
    export CLAUDE_CONFIG_DIR="''${CLAUDE_CONFIG_DIR:-$HOME/.claude2}"
    exec ${claudePkg}/bin/claude "$@"
  '';

  home = config.home.homeDirectory;

  # Declarative slice of ~/.claude/settings.json. We merge this into the
  # *live* file on activation rather than symlinking it from the store: the
  # file has to stay writable so interactive settings (/config, effort
  # toggles, dialog flags) persist and so claude2's out-of-store symlink
  # keeps working. Every top-level key listed in `settings` is owned verbatim
  # by the flake (shallow `+`, managed wins). Untouched keys stay live.
  managedSettings = pkgs.writeText "claude-settings.json" (builtins.toJSON cfg.settings);

  mergeSettings = pkgs.writeShellScript "claude-merge-settings" ''
    set -euo pipefail
    f="$1"
    mkdir -p "$(dirname "$f")"
    tmp="$f.tmp.$$"
    trap 'rm -f "$tmp"' EXIT
    if [ -f "$f" ] && ${pkgs.jq}/bin/jq -e . "$f" >/dev/null 2>&1; then
      ${pkgs.jq}/bin/jq -s '.[0] + .[1]' "$f" ${managedSettings} > "$tmp"
    else
      if [ -f "$f" ]; then
        echo "claude-merge-settings: $f is not valid JSON. Moving it to $f.invalid" >&2
        mv "$f" "$f.invalid"
      fi
      # install, not cp: a store file is 0444 and cp would propagate that,
      # leaving the live file read-only on first run.
      install -m 0644 ${managedSettings} "$tmp"
    fi
    mv "$tmp" "$f"
  '';

  # ASD-STE100 skill (`/asd-ste100`, the `ste100` plugin in the
  # `byteful-skills` flake input): Simplified Technical English rules for
  # rewriting ambiguous agent-facing English. SKILL.md points at references/
  # and examples/, so the whole skill dir is linked as-is. opencode scans
  # ~/.claude/skills too, so this one link serves both tools (see
  # opencode.nix).
  ste100Skill = "${inputs.byteful-skills}/plugins/ste100/skills/asd-ste100";

  # The user memory below turns the STE100 ruleset on for every reply, but
  # that memory loads once at session start and fades as a long session fills
  # the context. This text lands next to the newest prompt instead, for a few
  # tokens a turn. Keep it short.
  ste100Reminder = pkgs.writeText "ste100-reminder.txt" ''
    STE100 reminder, from ~/.claude/CLAUDE.md. Apply the ASD-STE100 ruleset
    (~/.claude/skills/asd-ste100/SKILL.md) to the prose in this reply.
    STE-flavored mode for chat text, comments, commit messages and docs.
    Strict mode for machine-facing strings: error messages, tool
    descriptions, prompts. Short sentences, active voice, one instruction
    per sentence, no phrasal verbs, no semicolons. Keep every hedge and
    every claim.
  '';

  # A UserPromptSubmit hook that exits 0 hands its plain stdout to the model as
  # context, so the whole hook is one `cat`.
  ste100PromptHook = pkgs.writeShellScript "ste100-prompt-hook" ''
    exec ${pkgs.coreutils}/bin/cat ${ste100Reminder}
  '';

  # shadcn/improve ships read-only from the flake input. Copy it out, append our
  # machine addendum (Nushell shell, flake-managed installs, Nushell cleanup
  # commands) to SKILL.md, and bump the default executor from sonnet to opus, so
  # both customisations are re-applied on every input bump. --replace-fail makes
  # an input reword that loses the patch break the build instead of silently
  # reverting the executor to sonnet.
  improveSkill = pkgs.runCommand "improve-skill" { } ''
    mkdir -p $out
    cp -r ${inputs.improve-skill}/skills/improve/. $out/
    chmod -R u+w $out
    cat ${./improve-skill-addendum.md} ${./improve-addendum-shared.md} >> $out/SKILL.md
    substituteInPlace $out/references/closing-the-loop.md \
      --replace-fail 'Executor model: default `sonnet`;' \
                     'Executor model: default `opus` (dispatch it at high reasoning effort);'
  '';
in
{
  options.dotfiles.dev.claude-code = {
    enable = lib.mkEnableOption "Claude Code CLI with a second account (claude + claude2)" // {
      default = true;
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      example = lib.literalExpression ''
        {
          theme = "dark";
          attribution = {
            commit = "";
            pr = "";
          };
        }
      '';
      description = ''
        Top-level keys merged into the live ~/.claude/settings.json on each
        activation. Each key listed here is owned verbatim by the flake and
        overwrites whatever is in the live file (so interactive edits to these
        keys revert on the next switch). Keys NOT listed stay freely editable
        from inside Claude Code. Shared with claude2.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [
        claudePkg
        claude2
      ];

      # claude2 borrows account 1's settings, skills, agents and plugins so you
      # configure them once. These are out-of-store symlinks to the live files
      # under ~/.claude, so edits from either command are shared. Login and
      # history (.credentials.json, .claude.json, projects/) are intentionally
      # NOT linked and stay separate per account.
      file = {
        ".claude2/settings.json".source =
          config.lib.file.mkOutOfStoreSymlink "${home}/.claude/settings.json";
        ".claude2/skills".source = config.lib.file.mkOutOfStoreSymlink "${home}/.claude/skills";
        ".claude2/agents".source = config.lib.file.mkOutOfStoreSymlink "${home}/.claude/agents";
        ".claude2/plugins".source = config.lib.file.mkOutOfStoreSymlink "${home}/.claude/plugins";
        # Output styles ride along too: the shared settings.json stores the
        # selected style by name, so both accounts must see the same files.
        ".claude2/output-styles".source =
          config.lib.file.mkOutOfStoreSymlink "${home}/.claude/output-styles";

        # Guarantee the shared dirs exist so the symlinks above never dangle.
        ".claude/skills/.keep".text = "";
        ".claude/agents/.keep".text = "";
        ".claude/plugins/.keep".text = "";
        ".claude/output-styles/.keep".text = "";

        # Third-party skill: shadcn/improve, a read-only codebase auditor that
        # writes execution plans (`/improve`). Pinned via the `improve-skill`
        # flake input, then patched by `improveSkill` above to append our
        # environment addendum to SKILL.md. Living under ~/.claude/skills, it's
        # automatically shared with claude2 through the skills symlink above.
        ".claude/skills/improve".source = improveSkill;

        # ASD-STE100 skill (`/asd-ste100`): Simplified Technical English.
        # Shared with claude2 through the skills symlink above.
        ".claude/skills/asd-ste100".source = ste100Skill;

        # STE100 as an output style. Installing the file only makes it appear
        # in the picker. Select it with /config -> Output style. The choice
        # lands in the shared settings.json under a key the flake does not
        # own, so it stays interactively editable.
        ".claude/output-styles/ste100.md".source = ./ste-writing/ste100-output-style.md;

        # User memory (~/.claude/CLAUDE.md): turns the STE100 ruleset on
        # for all prose. It imports the skill file above with an @-reference,
        # so the two entries must stay installed together. Store-managed, so edit
        # modules/dev/claude-user-memory.md and rebuild. The `#` memory
        # shortcut cannot write to it. claude2 gets its own copy because its
        # config dir does not inherit CLAUDE.md through a symlink.
        ".claude/CLAUDE.md".source = ./claude-user-memory.md;
        ".claude2/CLAUDE.md".source = ./claude-user-memory.md;
      };

      activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${mergeSettings} "${home}/.claude/settings.json"
      '';
    };

    # Stable, cross-host slice of settings.json owned by the flake. Anything
    # not listed here (e.g. one-off toggles) stays interactively editable.
    dotfiles.dev.claude-code.settings = {
      attribution = {
        commit = "";
        pr = "";
      };
      # Follows dotfiles.theme.variant, so the TUI matches the terminal it
      # runs in. "dark"/"light" are both valid Claude Code theme names.
      theme = config.dotfiles.theme.variant;
      effortLevel = "xhigh";
      switchModelsOnFlag = false;
      # Applies the STE100 ruleset from claude-user-memory.md to every reply.
      # The reminder repeats on each prompt, so it sits next to the newest
      # turn rather than at the top of the session. The `hooks` key is
      # flake-owned, so /hooks edits revert on the next switch.
      hooks.UserPromptSubmit = [
        {
          hooks = [
            {
              type = "command";
              command = "${ste100PromptHook}";
              timeout = 5;
            }
          ];
        }
      ];
      skipWorkflowUsageWarning = true;
      enabledPlugins = {
        "rust-analyzer-lsp@claude-plugins-official" = true;
        "superpowers@claude-plugins-official" = true;
        "code-simplifier@claude-plugins-official" = true;
        "claude-md-management@claude-plugins-official" = true;
        "greptile@claude-plugins-official" = true;
        "gopls-lsp@claude-plugins-official" = true;
      };
      # Kept empty on purpose: the settings merge is shallow and managed keys
      # win, so an empty attrset scrubs stale third-party marketplaces (for
      # example byteful-skills) from the live file on the next switch.
      extraKnownMarketplaces = { };
    };
  };
}
