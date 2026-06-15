{
  config,
  lib,
  pkgs,
  monoFont,
  serifFont,
  base16Scheme,
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
    qt = {
      enable = true;
      # Override stylix's own qt target (which defaults to qtct). We want
      # qt apps to follow the gtk theme instead.
      platformTheme.name = lib.mkForce "gtk";
    };

    # The gtk platform theme above makes Qt apps open native GTK3 file
    # dialogs, and GTK3 aborts the whole process (fatal g_log) if the
    # org.gtk.Settings.FileChooser GSettings schema isn't on XDG_DATA_DIRS.
    # Nothing else in this config publishes compiled schemas, so every Qt
    # file dialog (FreeCAD Open/Save As, ...) would crash without these.
    xdg.systemDirs.data = [
      "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
      "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
    ];

    stylix = {
      enable = true;
      polarity = config.dotfiles.theme.variant;

      image = config.dotfiles.theme.wallpaper;

      # The palette itself, not a yaml from base16-schemes. Every base00-0F
      # value comes from `modules/theming/palette.nix`, so `stylix.override`
      # is unnecessary — there is nothing underneath to paint over.
      inherit base16Scheme;

      fonts = {
        monospace.name = monoFont;
        serif.name = serifFont;
        sansSerif.name = serifFont;

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

      # Per-target overrides: stylix only configures a target when its module
      # is enabled. firefox/spicetify/zellij/mako are disabled so other modules
      # (textfox, spicetify customColorScheme, etc.) can own that theming; the
      # active terminal defers to stylix (its module forces a custom palette on
      # top).
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
        (lib.mkIf config.dotfiles.desktop.lock.enable {
          # lock.nix owns hyprlock theming: this target would force the
          # static wallpaper as the lock background instead of the live
          # blurred screenshot.
          hyprlock.enable = false;
        })
        (lib.mkIf (config.dotfiles.terminals.primary == "ghostty") {
          ghostty.enable = true;
        })
        (lib.mkIf (config.dotfiles.terminals.primary == "alacritty") {
          alacritty.enable = true;
        })
      ];
    };
  };
}
