{
  colors,
  border-style,
  shadow-style,
  config,
  lib,
  ...
}:

let
  cfg = config.dotfiles.theming.gtk;

  width = toString border-style.width;
  radius = toString border-style.radius-int;
  offset = toString shadow-style.offset;

  # Every rule below sits under this scope. Walker loads its theme at the
  # same USER priority as ~/.config/gtk-4.0/gtk.css, so an unscoped rule
  # such as `entry { border }` beats walker's `* { all: unset }` and draws a
  # second frame inside the launcher. Walker's layout gives its GtkWindow the
  # `window` class (resources/themes/default/layout.xml upstream), and no
  # standard GTK toplevel carries it, so this leaves walker to its own theme
  # (desktop/walker.nix). eww is a GTK3 app with the same problem: its
  # stylesheet loads below USER priority, so the button rule removed the
  # power buttons' shadow and border. eww adds each window's name as a class
  # on its GtkWindow (crates/eww/src/app.rs upstream), so `.powermenu`, the
  # only eww window (eww/eww.yuck), leaves eww to eww/eww.scss.
  scope = "window:not(.window):not(.powermenu)";
in
{
  options.dotfiles.theming.gtk.enable = lib.mkEnableOption "TUI-style GTK3 and GTK4 widget CSS" // {
    default = true;
  };

  # The font needs no rule here: stylix sets `gtk.font` from its sansSerif
  # font, and theming/stylix.nix points that at the monospace family.
  #
  # Stylix appends this string to both gtk-3.0/gtk.css and gtk-4.0/gtk.css,
  # so every selector and property must parse in both versions. Focus
  # colours go through `outline-color` with no pseudo-class. The theme sets
  # the outline width only on focus, and this USER-priority colour wins over
  # the theme's, so one rule covers every focus state in both versions.
  #
  # A resting border is `bg2`, the dark grey that spicetify's
  # `border-inactive` uses (apps/spicetify.nix), not the gold-brown niri
  # `borderInactive`. The niri border pair frames windows. Inside an app, the
  # resting frame stays grey and only focus takes the active colour.
  config = lib.mkIf cfg.enable {
    stylix.targets.gtk.extraCss = ''
      /* Hard edges everywhere, as on the niri windows. A universal rule
         rather than a node list, so a renamed libadwaita node still loses
         its corners. Tooltips are their own surface outside any window. */
      ${scope},
      ${scope} *,
      tooltip,
      tooltip * {
        border-radius: ${radius}px;
      }

      tooltip {
        border: ${width}px solid #${colors.bg2};
      }

      /* Buttons: flat and unframed at rest. A frame at rest put a box on
         every column header and every per-row star in Nautilus. The border
         keeps its width while transparent, so hover does not move the
         layout. The grey resting border on hover, the active border while
         held or toggled. */
      ${scope} button {
        background-image: none;
        box-shadow: none;
        border: ${width}px solid transparent;
        outline-color: #${colors.borderActive};
      }

      ${scope} button:hover {
        border-color: #${colors.bg2};
      }

      ${scope} button:active,
      ${scope} button:checked {
        border-color: #${colors.borderActive};
      }

      ${scope} button:checked {
        background-color: #${colors.bg3};
      }

      /* Text fields: the same frame. The focus outline lands on it. */
      ${scope} entry,
      ${scope} spinbutton {
        box-shadow: none;
        border: ${width}px solid #${colors.bg2};
        outline-color: #${colors.borderActive};
      }

      /* A hard rule under every header bar and beside every sidebar, in
         place of libadwaita's soft shade. */
      ${scope} headerbar {
        box-shadow: none;
        border-bottom: ${width}px solid #${colors.bg2};
      }

      ${scope} .sidebar-pane {
        box-shadow: inset -${width}px 0 #${colors.bg2};
      }

      /* Popovers (GTK4) and menus (GTK3): the active border and the hard
         offset shadow a niri window casts. The arrow takes the same border
         width, because GTK aligns it to the contents border. */
      ${scope} popover > contents {
        border: ${width}px solid #${colors.borderActive};
        box-shadow: ${offset}px ${offset}px 0 #${colors.shadow};
      }

      ${scope} popover > arrow {
        border: ${width}px solid #${colors.borderActive};
      }

      ${scope} menu {
        border: ${width}px solid #${colors.borderActive};
      }

      /* Selection: a bg3 block, and on list rows a left bar in the
         signature colour, like a TUI cursor line. */
      ${scope} row:selected,
      ${scope} gridview > child:selected,
      ${scope} treeview.view:selected {
        background-color: #${colors.bg3};
      }

      ${scope} row:selected {
        box-shadow: inset ${width}px 0 #${colors.primary};
      }

      /* The keyboard focus ring on rows and grid cells, in the palette
         rather than libadwaita's light grey. */
      ${scope} row,
      ${scope} gridview > child {
        outline-color: #${colors.bg2};
      }
    '';
  };
}
