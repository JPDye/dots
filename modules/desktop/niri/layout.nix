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
              active-color "#${colors.borderActive}"
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
          active.color = "#${colors.borderActive}";
          inactive.color = "#${colors.borderInactive}";
        };

        # A hard offset seam, the same one eww's boxes draw: softness 0
        # keeps the edge hard, spread 0 keeps the shadow the window's own
        # size, and the 2px offset is the only thing that shows it. The
        # colour is the palette's shared `shadow` token rather than bg0,
        # because an offset shadow has to read against the wallpaper rather
        # than mask a gap.
        shadow = {
          enable = true;
          spread = 0;
          softness = 0;
          offset = {
            x = 2;
            y = 2;
          };

          color = "#${colors.shadow}";
          inactive-color = "#${colors.shadow}";
        };

        # Pull windows back toward the screen edges so the outer gap stays
        # at 4px (gaps + strut) while the inner gaps widen.
        struts = {
          top = 4;
          bottom = 4;
          left = 4;
          right = 4;
        };
      };
    };
  };
}
