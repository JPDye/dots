{
  colors,
  config,
  lib,
  ...
}:

{
  config = lib.mkIf config.dotfiles.desktop.niri.enable {
    programs.niri.settings = {
      overview = {
        backdrop-color = "#${colors.bg0}";
        zoom = 0.6;
        workspace-shadow = {
          softness = 0;
          spread = 3;
          offset = {
            x = 0;
            y = 0;
          };
          color = "#${colors.orange}";
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
          { proportion = 0.33333; }
          { proportion = 0.5; }
          { proportion = 0.66667; }
        ];

        default-column-width = {
          proportion = 0.3333;
        };

        focus-ring.enable = false;

        border = {
          enable = true;
          width = 1;
          active.color = "#${colors.border}";
          inactive.color = "#${colors.mid}";
        };

        # Spread exceeds half the gap (16/2 = 8), so neighbouring windows'
        # shadows overlap and no backdrop shows through between them; the
        # softness only feathers the outer edge past that solid core.
        shadow = {
          enable = true;
          spread = 10;
          softness = 8;
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
          top = -12;
          bottom = -12;
          left = -12;
          right = -12;
        };
      };
    };
  };
}
