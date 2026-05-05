{
  config,
  lib,
  colors,
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
            "1" = "#${colors.green}";
            "2" = "#${colors.orange}";
            "3" = "#${colors.red}";
            "4" = "#${colors.orange}";
            "5" = "#${colors.green}";
            "6" = "#${colors.red}";
          };
        };

        display = {
          separator = " | ";

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
          "break"

          {
            type = "Datetime";
            key = "";
            format = "{12} {5} {1}";
          }

          {
            type = "Datetime";
            key = "󰥔";
            format = "{14}:{18}";
          }

          "break"

          {
            type = "wm";
            key = "";
            format = "{2}";
          }

          {
            type = "terminal";
            key = "";
            format = "{5}";
          }

          {
            type = "editor";
            key = "";
            format = "{2}";
          }

          "break"

          {
            type = "media";
            key = "";
            format = "{3}";

          }
          {
            type = "media";
            key = "󰀥";
            format = "{4}";

          }
          {
            type = "media";
            key = "";
            format = "{1}";
          }

          "break"

          {
            type = "cpuusage";
            key = "";
            inherit percent;
          }

          {
            type = "memory";
            key = "";
            inherit percent;
          }

          {
            type = "disk";
            inherit percent;
            key = "󰋊";
          }

          "break"
          "break"
          "break"
        ];
      };
    };
  };
}
