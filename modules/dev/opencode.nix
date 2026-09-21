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

  # The patched STE100 skill, one store path shared with claude-code.nix.
  ste100Skill = import ./ste100-skill.nix { inherit pkgs inputs; };

  # Global rules (~/.config/opencode/AGENTS.md): the same "STE100 always on"
  # user memory Claude Code gets via ~/.claude/CLAUDE.md, built from the same
  # source file so the two stay in lockstep. opencode does not parse
  # @-imports in rules files, so the @-reference is swapped for the full
  # STE100 ruleset (frontmatter stripped) at build time. The inlined text is
  # the patched copy from ./ste100-skill.nix, house rules included, so it
  # matches what Claude Code reads. The skill itself stays invocable as
  # `asd-ste100`: opencode discovers it from ~/.claude/skills, where
  # claude-code.nix links the same store path. Do not link a second copy under
  # ~/.config/opencode/skills: opencode wants skill names unique across every
  # scanned dir and warns on a duplicate.
  agentsMd = pkgs.runCommand "opencode-agents-md" { } ''
    substitute ${./claude-user-memory.md} $out \
      --replace-fail '@~/.claude/skills/asd-ste100/SKILL.md' \
                     '(inlined below from the asd-ste100 skill)'
    awk '/^---$/ && c < 2 { c++; next } c == 2' \
      ${ste100Skill}/SKILL.md >> $out
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
    if [ -f "$f" ] && ${pkgs.jq}/bin/jq -e . "$f" >/dev/null 2>&1; then
      ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$f" ${managedConfig} > "$tmp"
    else
      if [ -f "$f" ]; then
        echo "opencode-merge-config: $f is not valid JSON. Moving it to $f.invalid" >&2
        mv "$f" "$f.invalid"
      fi
      # install, not cp: a store file is 0444 and cp would propagate that,
      # leaving the live file read-only on first run.
      install -m 0644 ${managedConfig} "$tmp"
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

      file = {
        # opencode reads skills from ~/.config/opencode/skills/<name>/SKILL.md.
        ".config/opencode/skills/improve-oc".source = improveSkill;

        # STE100 always on for all prose (see agentsMd above).
        ".config/opencode/AGENTS.md".source = agentsMd;
      };

      activation.opencodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${mergeConfig} "${home}/.config/opencode/opencode.json"
      '';
    };
  };
}
