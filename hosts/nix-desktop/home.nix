# Per-host home-manager overlay: monitor outputs, lib.mkForce bind overrides,
# and nothing else — packages belong in the shared home.nix (see CLAUDE.md).
{ lib, ... }:

{
  programs.niri.settings = {
    outputs = {
      "DP-3" = {
        scale = 1.0;
        focus-at-startup = true;

        mode = {
          width = 5120;
          height = 2160;
          refresh = 165.0;
        };
      };
    };

    # Per-host window rules. home-manager concatenates list options, so these
    # append to the shared baseline in modules/desktop/niri/window-rules.nix
    # rather than replacing it. Match on app-id / title (both regexes); find a
    # window's values with `niri msg windows`.
    window-rules = [
      {
        matches = [ { app-id = "^org.gnome.Calculator$"; } ];
        open-floating = true;
        default-column-width = {
          proportion = 0.25;
        };
      }
    ];

    # Per-host layout. Unlike window-rules (a list that concatenates), layout is
    # an attrset that deep-merges with the shared base in
    # modules/desktop/niri/layout.nix. A key the base doesn't set merges in
    # cleanly; overriding a key the base already sets (gaps, default-column-width,
    # border.*, shadow.*, struts.*) needs lib.mkForce to win the conflict.
    layout = {
      # New key — base doesn't set it, so no mkForce:
      always-center-single-column = true;

      # Override the base border width (base sets 2) down to 1px.
      border.width = lib.mkForce 1;

      preset-column-widths = [
        { proportion = 0.25; }
        { proportion = 0.333; }
        { proportion = 0.5; }
        { proportion = 0.666; }
        { proportion = 0.75; }
      ];
    };
  };
}
