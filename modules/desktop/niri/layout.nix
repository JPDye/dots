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
        gaps = 8;
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

        shadow = {
          enable = true;
          spread = 5;
          softness = 0;
          offset = {
            x = 0;
            y = 0;
          };
          color = "#${colors.bg0}";
          inactive-color = "#${colors.bg0}";
        };

        struts = {
          top = -4;
          bottom = -4;
          left = -4;
          right = -4;
        };
      };
    };
  };
}
