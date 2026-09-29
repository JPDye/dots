{
  colors,
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
      # qt apps to follow the gtk theme instead. `gtk3` is Qt's own GTK3
      # platform theme plugin — not the legacy `gtk2` qtstyleplugins path. The
      # old alias `gtk` warns since home-manager 26.05.
      platformTheme.name = lib.mkForce "gtk3";
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
      polarity = "dark";

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
          # One point under the rest. This is the only size the terminal
          # reads, and ghostty's own font-size step is 1pt, so 13 is exactly
          # one step down from the 14 the other surfaces use.
          terminal = 13;
        };
      };

      # Bibata Original, re-rendered in the palette (see
      # pkgs/bibata-cursors-themed). The body is the signature gold, so it
      # reads against every dark surface here. The outline is the shared
      # `shadow` seam, so the cursor keeps an edge over light content too.
      cursor =
        let
          package = pkgs.callPackage ../../pkgs/bibata-cursors-themed {
            baseColor = "#${colors.primary}";
            outlineColor = "#${colors.shadow}";
            watchBackgroundColor = "#${colors.bg0}";
          };
        in
        {
          inherit package;
          name = package.themeName;
          size = 16;
        };

      # Gruvbox Plus, the flat icon pack cut for the gruvbox palette that
      # kintsugi builds on. `gold` is the pack's nearest named folder colour
      # to the signature `primary` gold. The pack ships no colour by hex.
      # Stylix's stylix/hm/icons.nix sets `gtk.iconTheme` from this, so GTK
      # and Qt get the same theme with no second definition here.
      icons =
        let
          package = pkgs.gruvbox-plus-icons.override { folder-color = "gold"; };
        in
        {
          enable = true;
          inherit package;
          dark = "Gruvbox-Plus-Dark";
          light = "Gruvbox-Plus-Light";
        };

      # Per-target overrides: stylix only configures a target when its module
      # is enabled. firefox/spicetify/zellij/mako/helix are disabled so other
      # modules (textfox, spicetify customColorScheme, etc.) can own that
      # theming; the active terminal defers to stylix (its module forces a
      # custom palette on top).
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
        (lib.mkIf config.dotfiles.dev.helix.enable {
          # dev/helix/themes.nix owns the helix theme. Both modules write
          # `programs.helix.themes.<name>`, but stylix writes a rendered TOML
          # *file* while ours writes an attrset, and the two do not merge:
          # stylix's file won silently and this flake's theme never reached
          # helix. Turning the target off leaves one writer.
          helix.enable = false;
        })
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
