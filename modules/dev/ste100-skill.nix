# The ASD-STE100 skill (`asd-ste100`, the `ste100` plugin in the
# `byteful-skills` flake input) with this repo's house-rule addendum
# appended to SKILL.md. The addendum adds the em-dash ban and the
# no-cataphoric-teaser rule, both stricter than official STE.
#
# A plain function, not a module, so both agent modules import it and get
# one store path: claude-code.nix links it into ~/.claude/skills (where
# opencode also discovers it), and opencode.nix inlines its SKILL.md into
# ~/.config/opencode/AGENTS.md. Same pattern as modules/theming/palette.nix.
{ pkgs, inputs }:
let
  upstream = "${inputs.byteful-skills}/plugins/ste100/skills/asd-ste100";
in
pkgs.runCommand "ste100-skill" { } ''
  mkdir -p $out
  cp -r ${upstream}/. $out/
  chmod -R u+w $out
  cat ${./ste-writing/ste100-house-rules-addendum.md} >> $out/SKILL.md
''
