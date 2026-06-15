# Per-host home-manager overlay: monitor outputs, lib.mkForce bind overrides,
# and nothing else — packages belong in the shared home.nix (see CLAUDE.md).
_:

{
  programs.niri.settings.outputs = {
    "eDP-1" = {
      scale = 1.0;
      focus-at-startup = true;
    };
  };
}
