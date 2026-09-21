{
  border-style,
  colors,
  config,
  lib,
  themeLib,
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
        # A solid ring, not a depth shadow. softness 0 keeps a hard edge,
        # because the shader punches the view rect back out, and a zero
        # offset keeps the ring even on all four sides.
        #
        # niri scales spread by `view_size.h / 1080`
        # (compute_workspace_shadow_config, src/layout/workspace.rs) and the
        # overview zoom (0.6 above) scales it again at render time. On a
        # 2160-tall output that is 2 * 0.6 = 1.2, so spread 1.67 lands on
        # ~2px zoomed out. The 1200-tall laptop panel scales by 1.111 * 0.6
        # = 0.667 instead, so the ring reads ~1px there. One spread cannot
        # hit 2px on both.
        #
        # The colour stays darker than `backdrop-color`, which is bg0: a
        # ring cannot read against its own colour.
        workspace-shadow = {
          softness = 0;
          spread = 1.67;
          offset = {
            x = 0;
            y = 0;
          };
          color = "#${themeLib.mix 0.6 colors.bg0 "000000"}";
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
          inherit (border-style) width;
          active.color = "#${colors.border}";
          inactive.color = "#${colors.neutral}";
        };

        # Spread exceeds half the gap (16/2 = 8) so neighbouring windows'
        # shadows meet across it. softness 0 keeps a hard edge past the
        # overlap.
        shadow = {
          enable = true;
          spread = 2;
          softness = 0;
          offset = {
            x = 0;
            y = 0;
          };

          color = "#${colors.bg0}";
          inactive-color = "#${colors.bg0}";
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
