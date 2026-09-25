{
  border-style,
  shadow-style,
  colors,
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
        # The same hard offset seam the window shadow below draws: spread 0
        # keeps the shadow the workspace's own size, softness 0 keeps the
        # edge hard, and the offset is the only thing that shows it.
        #
        # The number is not the window offset. niri multiplies softness, spread AND offset by
        # `view_size.h / 1080` (compute_workspace_shadow_config,
        # src/layout/workspace.rs), and the overview then draws the whole
        # workspace at the zoom above. So what lands on screen is
        #
        #     configured * (view_h / 1080) * zoom
        #
        # while a window inside the overview shows its own offset at just
        # `offset * zoom`. Setting configured = offset * 1080 / view_h makes
        # the two match: half the offset on a 2160-tall output, which is what
        # this targets, the same output the old spread was tuned against. A
        # 1200-tall panel would want 0.9 of it, and one value cannot serve
        # both.
        #
        # The colour stays darker than `backdrop-color`, which is bg0: a
        # shadow cannot read against its own colour.
        workspace-shadow = {
          softness = 0;
          spread = 0;
          offset = {
            x = shadow-style.offset / 2.0;
            y = shadow-style.offset / 2.0;
          };
          color = "#${colors.shadow}";
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

        # A hard offset seam, the same shape eww's boxes draw 2px shallower:
        # softness 0 keeps the edge hard, spread 0 keeps the shadow the
        # window's own size, and the `shadow-style.offset` is the only thing
        # that shows it. A float, walker and the lock card cast the same. A
        # window throws the deepest shadow on the desktop, and everything
        # smaller sits a step under it. The colour is the
        # palette's shared `shadow` token rather than bg0, because an offset
        # shadow has to read against the wallpaper rather than mask a gap.
        shadow = {
          enable = true;
          spread = 0;
          softness = 0;
          offset = {
            x = shadow-style.offset;
            y = shadow-style.offset;
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
