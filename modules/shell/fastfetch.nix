{
  config,
  lib,
  colors,
  themeLib,
  ...
}:

let
  cfg = config.dotfiles.shell.fastfetch;
  percent = {
    type = 6;
    green = 30;
    cyan = 60;
    red = 100;
  };

  # Row of palette dots bracketing the output, derived from the theme so a
  # re-skin propagates here.
  paletteDots = {
    type = "custom";
    format = lib.concatMapStringsSep "  " (c: "{#38;2;${themeLib.rgbDec c}}●") (
      with colors;
      [
        red
        orange
        yellow
        green
        blue
        pink
      ]
    );
  };
in
{
  options.dotfiles.shell.fastfetch.enable = lib.mkEnableOption "fastfetch sysinfo" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    programs.fastfetch = {
      enable = true;

      settings = {
        logo = {
          source = "nixos";

          padding = {
            top = 1;
            left = 1;
            right = 4;
          };

          color = {
            "1" = "#${colors.red}";
            "2" = "#${colors.red}";
            "3" = "#${colors.orange}";
            "4" = "#${colors.orange}";
            "5" = "#${colors.green}";
            "6" = "#${colors.green}";
          };
        };

        display = {
          separator = " · ";

          color = {
            keys = "#${colors.orange}";
          };

          key = {
            type = "string";
          };
        };

        modules = [
          "break"
          "break"
          "break"

          paletteDots

          "break"

          {
            type = "Datetime";
            key = "";
            format = "{12} {5} {1}";
          }

          {
            type = "Datetime";
            key = "󰥔";
            format = "{14}:{18}";
          }

          "break"

          {
            type = "media";
            key = "";
            format = "{3}";

          }
          {
            type = "media";
            key = "󰀥";
            format = "{4}";

          }
          {
            type = "media";
            key = "";
            format = "{1}";
          }

          "break"

          {
            type = "cpuusage";
            key = "";
            inherit percent;
          }

          {
            type = "memory";
            key = "";
            inherit percent;
          }

          {
            type = "disk";
            inherit percent;
            key = "󰋊";
          }

          "break"

          paletteDots

          "break"
          "break"
          "break"
        ];
      };
    };
  };
}
