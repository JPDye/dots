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

      // The whole overview section is raw KDL: the niri-fork input adds
      // `workspace-border`, which niri-flake's schema does not know, and niri
      // rejects a second `overview` node in one file. So the typed settings
      // cannot carry any part of it.
      //
      // The workspace shadow is the same hard even ring the window shadow
      // draws: offset 0 centres it, softness 0 keeps the edge hard, and the
      // spread is the only thing that shows it, on all four sides. niri
      // multiplies softness, spread AND offset by `view_size.h / 1080`
      // (compute_workspace_shadow_config, src/layout/workspace.rs), and the
      // overview then draws the whole workspace at the zoom. So what lands
      // on screen is
      //
      //     configured * (view_h / 1080) * zoom
      //
      // while a window inside the overview shows its own ring at just
      // `spread * zoom`. Half the spread would match the two on a 2160-tall
      // output. The window spread plus 2px (6px) below makes the workspace
      // cast about 3 times the window's ring there, and about 1.7 times on a
      // 1200-tall panel, so a workspace reads apart from the windows in it. The colour stays
      // darker than `backdrop-color`, which is bg0: a shadow cannot read
      // against its own colour.
      //
      // The workspace border is the window border plus 2px. The fork draws
      // it in workspace space and applies the overview zoom, so the extra
      // 2px gives a line 2px thicker than a window border at zoom 1.
      overview {
          backdrop-color "#${colors.bg0}"
          zoom 0.6
          workspace-shadow {
              softness 0
              spread ${toString (shadow-style.offset + 2)}
              offset x=0 y=0
              color "#${colors.shadow}"
          }
          workspace-border {
              on
              width ${toString (border-style.width + 2)}
              active-color "#${colors.borderActive}"
              inactive-color "#${colors.borderInactive}"
          }
      }
    '';

    programs.niri.settings = {
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
        # Keep the empty workspace above the first one as well as below the
        # last, so a new workspace can open on either side.
        empty-workspace-above-first = true;

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

        # A hard even ring, the same shape eww's boxes draw 1px thinner:
        # softness 0 keeps the edge hard, offset 0 centres the shadow on the
        # window, and a spread of `shadow-style.offset` is the only thing
        # that shows it, on all four sides. A float casts the same. A
        # window throws the deepest shadow on the desktop, and everything
        # smaller sits a step under it. The colour is the
        # palette's shared `shadow` token rather than bg0, because an offset
        # shadow has to read against the wallpaper rather than mask a gap.
        shadow = {
          enable = true;
          spread = shadow-style.offset;
          softness = 0;
          offset = {
            x = 0;
            y = 0;
          };

          color = "#${colors.shadow}";
          # An unfocused window casts a slightly lighter seam than the
          # focused one, so focus shows in the shadow as well as the border.
          inactive-color = "#${colors.shadowInactive}";
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
