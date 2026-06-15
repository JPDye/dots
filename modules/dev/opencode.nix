{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.dev.opencode;

  home = config.home.homeDirectory;

  # opencode auto-discovers skills from ~/.claude/skills too, where the Claude
  # Code copy of shadcn/improve lives with an *opus* executor — a model opencode
  # can't run here. We ship an opencode-native copy named `improve-oc` (opencode
  # requires skill names be unique across all scanned dirs and can't be told
  # which dirs to scan, so it can't share the `improve` name with the Claude
  # copy) and deny the Claude `improve` in opencode below, so the agent only ever
  # loads this gpt-oss-wired one. Built from the same `improve-skill` input as the
  # Claude copy so version bumps stay in lockstep; --replace-fail makes an input
  # reword that loses a patch break the build instead of silently reverting.
  improveSkill = pkgs.runCommand "opencode-improve-skill" { } ''
    mkdir -p $out
    cp -r ${inputs.improve-skill}/skills/improve/. $out/
    chmod -R u+w $out
    substituteInPlace $out/SKILL.md \
      --replace-fail 'name: improve' 'name: improve-oc'
    cat ${./opencode-improve-addendum.md} ${./improve-addendum-shared.md} >> $out/SKILL.md
    substituteInPlace $out/references/closing-the-loop.md \
      --replace-fail 'Executor model: default `sonnet`;' \
                     'Executor model: the `improve-executor` opencode subagent (gpt-oss-120b via Groq);'
  '';

  # Flake-owned slice of opencode's config, deep-merged (`jq '.[0] * .[1]'`, so
  # managed leaves win) into the live ~/.config/opencode/opencode.json on
  # activation rather than symlinked — the file stays writable so the user's own
  # keys (providers, primary model, other agents) and opencode's interactive
  # edits survive.
  managedConfig = pkgs.writeText "opencode-config.json" (
    builtins.toJSON {
      "$schema" = "https://opencode.ai/config.json";

      # Hide the Claude Code `improve` (opus executor, unrunnable here) from
      # opencode so the agent can only load our gpt-oss-wired `improve-oc`.
      permission.skill = {
        "*" = "allow";
        improve = "deny";
      };

      # Default executor for `improve-oc`'s `execute` variant: gpt-oss-120b on
      # Groq, dispatched as an edit-capable subagent in an isolated worktree.
      agent.improve-executor = {
        description = "Executes a single improve-oc plan in an isolated git worktree, then stops for review. Dispatched by the improve-oc skill's execute variant.";
        mode = "subagent";
        model = "groq/openai/gpt-oss-120b";
        permission = {
          edit = "allow";
          bash = "allow";
        };
      };
    }
  );

  mergeConfig = pkgs.writeShellScript "opencode-merge-config" ''
    set -euo pipefail
    f="$1"
    mkdir -p "$(dirname "$f")"
    tmp="$f.tmp.$$"
    trap 'rm -f "$tmp"' EXIT
    if [ -f "$f" ]; then
      ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$f" ${managedConfig} > "$tmp"
    else
      cp ${managedConfig} "$tmp"
    fi
    mv "$tmp" "$f"
  '';
in
{
  options.dotfiles.dev.opencode.enable = lib.mkEnableOption "opencode AI coding agent" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [ pkgs.opencode ];

      # opencode reads skills from ~/.config/opencode/skills/<name>/SKILL.md.
      file.".config/opencode/skills/improve-oc".source = improveSkill;

      activation.opencodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${mergeConfig} "${home}/.config/opencode/opencode.json"
      '';
    };
  };
}
