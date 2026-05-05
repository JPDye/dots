{
  config,
  lib,
  pkgs,
  colors,
  monoFont,
  ...
}:

let
  cfg = config.dotfiles.theming.stylix;
in
{
  options.dotfiles.theming.stylix.enable = lib.mkEnableOption "system-wide stylix theming" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    gtk.gtk4.theme = config.gtk.theme;

    stylix = {
      enable = true;
      polarity = "dark";

      image = ../../wallpapers/socrates.jpg;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";

      fonts = {
        monospace.name = monoFont;
        serif.name = monoFont;
        sansSerif.name = monoFont;

        sizes = {
          applications = 14;
          desktop = 14;
          popups = 14;
          terminal = 14;
        };
      };

      cursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Original-Amber";
        size = 16;
      };

      override = lib.mkForce {
        base00 = "${colors.bg0}";
        base01 = "${colors.bg1}";
        base02 = "${colors.bg2}";
        base03 = "${colors.bg3}";
        base04 = "${colors.fg3}";
        base05 = "${colors.fg1}"; # ::<>, ()
        base06 = "${colors.fg1}";
        base07 = "${colors.fg0}";

        base08 = "${colors.orange}"; # self, fields, variables
        base09 = "${colors.yellow}"; # ints, booleans, constants
        base0A = "${colors.pink}"; # HashMap<String, String>;
        base0B = "${colors.green}"; # "abcdefg" and fields
        base0C = "${colors.orange}"; # "\n"
        base0D = "${colors.green}"; # println!, methods
        base0E = "${colors.red}"; # pub, impl, &, &mut
        base0F = "${colors.fg2}";
      };

      # Per-target overrides: stylix only configures a target when its module
      # is enabled. firefox/spicetify/zellij/mako are disabled so other modules
      # (textfox, spicetify customColorScheme, etc.) can own that theming;
      # ghostty defers to stylix.
      targets = lib.mkMerge [
        (lib.mkIf config.dotfiles.apps.firefox.enable {
          firefox.enable = false;
          firefox.profileNames = [ "jd" ];
        })
        (lib.mkIf config.dotfiles.apps.spicetify.enable {
          spicetify.enable = false;
        })
        (lib.mkIf config.dotfiles.terminals.zellij.enable {
          zellij.enable = false;
        })
        (lib.mkIf config.dotfiles.desktop.mako.enable { mako.enable = false; })
        (lib.mkIf config.dotfiles.terminals.ghostty.enable {
          ghostty.enable = true;
        })
      ];
    };
  };
}
