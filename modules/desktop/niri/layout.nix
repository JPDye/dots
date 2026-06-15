{
  colors,
  colorsDark,
  config,
  lib,
  ...
}:

{
  config = lib.mkIf config.dotfiles.desktop.niri.enable {
    # Alt-Tab switcher theming (niri 25.11+). Not in niri-flake's settings
    # schema yet, so it goes in as raw KDL via the extraConfig escape hatch.
    # Padding matches the layout gaps; square corners match the window rules.
    dotfiles.desktop.niri.extraConfig = ''
      recent-windows {
          highlight {
              active-color "#${colors.border}"
              urgent-color "#${colors.warning}"
              padding 16
              corner-radius 0
          }
      }
    '';

    programs.niri.settings = {
      overview = {
        backdrop-color = "#${colors.bg0}";
        zoom = 0.6;
        workspace-shadow = {
          softness = 0;
          spread = 2;
          offset = {
            x = 0;
            y = 0;
          };
          color = "#${colors.red}";
        };
      };

      input = {
        keyboard.xkb.layout = "gb";
        focus-follows-mouse = {
          enable = true;
          max-scroll-amount = "0%";
        };
      };

      layout = {
        background-color = "transparent";
        gaps = 16;
        center-focused-column = "never";

        preset-column-widths = [
          { proportion = 0.333; }
          { proportion = 0.5; }
          { proportion = 0.666; }
        ];

        default-column-width = {
          proportion = 0.333;
        };

        focus-ring.enable = false;

        border = {
          enable = true;
          width = 2;
          active.color = "#${colors.border}";
          inactive.color = "#${colors.mid}";
        };

        # Spread exceeds half the gap (16/2 = 8) so neighbouring windows'
        # shadows meet across it. softness 0 keeps a hard edge past the
        # overlap.
        #
        # The colour is pinned to the *dark* bg0 in both variants. This gap
        # fill is meant to read as a dark seam between windows, so it must
        # not follow the theme to cream when the light variant is active.
        shadow = {
          enable = true;
          spread = 2;
          softness = 0;
          offset = {
            x = 0;
            y = 0;
          };

          color = "#${colorsDark.bg0}";
          inactive-color = "#${colorsDark.bg0}";
        };

        # Pull windows back toward the screen edges so the outer gap stays
        # at 4px (gaps + strut) while the inner gaps widen.
        struts = {
          top = 0;
          bottom = 0;
          left = 0;
          right = 0;
        };
      };
    };
  };
}
