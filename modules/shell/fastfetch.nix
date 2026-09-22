{
  config,
  lib,
  colors,
  themeLib,
  ...
}:

let
  cfg = config.dotfiles.shell.fastfetch;
  # Only the three commented-out readouts below used this, so it stays
  # commented out with them. deadnix fails on an unused let binding.
  # percent = {
  #   type = 6;
  #   green = 30;
  #   cyan = 60;
  #   red = 100;
  # };

  # Row of palette dots bracketing the output, derived from the theme so a
  # re-skin propagates here. These name semantic roles, not hues: a hue name
  # means a different colour in each scheme, so `pink` drew a lilac under
  # kintsugi and a rose under gruvbox.
  paletteDots = {
    type = "custom";
    format = lib.concatMapStringsSep "  " (c: "{#38;2;${themeLib.rgbDec c}}●") (
      with colors;
      [
        gradient1
        gradient2
        gradient3
        gradient4
        gradient5
        gradient6
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
            "1" = "#${colors.tertiary}";
            "2" = "#${colors.tertiary}";
            "3" = "#${colors.secondary}";
            "4" = "#${colors.secondary}";
            "5" = "#${colors.primary}";
            "6" = "#${colors.primary}";
          };
        };

        display = {
          separator = " · ";

          color = {
            keys = "#${colors.accent}";
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

          # CPU, memory and disk readouts, switched off on 2026-09-20.
          # fastfetch runs on every new terminal (via welcome.nu), and cpuusage
          # alone cost 213 ms of fastfetch's 220 ms total, because it samples CPU
          # load across a fixed interval. Three extra "break" entries sit after
          # the closing palette dots below, so the output keeps its former
          # height.
          #
          # {
          #   type = "cpuusage";
          #   key = "";
          #   inherit percent;
          # }
          #
          # {
          #   type = "memory";
          #   key = "";
          #   inherit percent;
          # }
          #
          # {
          #   type = "disk";
          #   inherit percent;
          #   key = "󰋊";
          # }

          "break"

          paletteDots
        ];
      };
    };
  };
}
