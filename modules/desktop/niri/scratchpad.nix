{
  config,
  lib,
  inputs,
  system,
  ...
}:

let
  nscratch = lib.getExe inputs.niri-scratchpad.packages.${system}.default;
  scratch-id = "com.mitchellh.ghostty.scratch";
in
{
  config = lib.mkIf config.dotfiles.desktop.niri.enable {
    programs.niri.settings = {
      # The workspace scratchpad windows are stashed on. Named workspaces
      # always sort before dynamic ones, so this pins itself at index 1 —
      # the Mod+1..4 binds in binds.nix target indices 2..5 to compensate.
      workspaces.scratch = { };

      # Toggle the scratch terminal: summon it to the focused workspace, or
      # stash it back on "scratch" when it's already focused. Spawned on
      # first use; -m brings it to whichever monitor holds the focused
      # workspace. The window opens floating on "scratch" via the generic
      # `\.scratch$` rule in window-rules.nix, so further scratchpads only
      # need their own app-id suffix and a bind like this one.
      binds."Mod+Grave".action.spawn = [
        nscratch
        "-id"
        scratch-id
        "-s"
        "ghostty --class=${scratch-id}"
        "-m"
      ];
    };
  };
}
