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

          {
            type = "custom";
            format = "{#38;2;175;95;95}●  {#38;2;175;135;95}●  {#38;2;168;160;95}●  {#38;2;135;135;95}●  {#38;2;95;135;135}●  {#38;2;183;143;143}●";
          }

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

          # {
          #   type = "wm";
          #   key = "";
          #   format = "{2}";
          # }

          # {
          #   type = "terminal";
          #   key = "";
          #   format = "{5}";
          # }

          # {
          #   type = "editor";
          #   key = "󰏬";
          #   format = "{2}";
          # }

          # "break"

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

          {
            type = "custom";
            format = "{#38;2;175;95;95}●  {#38;2;175;135;95}●  {#38;2;168;160;95}●  {#38;2;135;135;95}●  {#38;2;95;135;135}●  {#38;2;183;143;143}●";
          }

          "break"
          "break"
          "break"
        ];
      };
    };
  };
}
