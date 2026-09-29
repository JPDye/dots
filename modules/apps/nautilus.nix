{
  colors,
  border-style,
  config,
  lib,
  ...
}:

let
  cfg = config.dotfiles.apps.nautilus;
  width = toString border-style.width;

  # `window.nautilus-window` is more specific than the global
  # `window:not(.window) button` in theming/gtk.nix, so these rules win
  # where the two set the same property.
  scope = "window.nautilus-window";
in
{
  options.dotfiles.apps.nautilus.enable = lib.mkEnableOption "TUI-style Nautilus CSS" // {
    default = true;
  };

  # CSS only. No package: pacman supplies Nautilus on laptop-arch. The class
  # names come from Nautilus's own stylesheet, which ships as the
  # /org/gnome/nautilus/style.css GResource inside the binary. Read it with
  # `gresource extract /usr/bin/nautilus /org/gnome/nautilus/style.css`.
  config = lib.mkIf cfg.enable {
    stylix.targets.gtk.extraCss = ''
      /* Path bar: one framed box, like a TUI status line, in place of the
         tinted pill. */
      ${scope} .nautilus-pathbar {
        background-color: transparent;
        border: ${width}px solid #${colors.bg2};
      }

      ${scope} .nautilus-path-button {
        margin: 0;
      }

      ${scope} .nautilus-path-button.current-dir {
        color: #${colors.primary};
      }

      /* The floating status bar at the bottom of the view. */
      ${scope} .floating-bar {
        box-shadow: none;
        border: ${width}px solid #${colors.bg2};
      }
    '';
  };
}
