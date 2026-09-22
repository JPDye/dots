{
  config,
  lib,
  colors,
  ...
}:

let
  cfg = config.dotfiles.terminals.zellij;
  # Emphasis tiers, muted to match helix's statusline rather than running
  # four saturated accents. helix keeps its bar on fg3/bg3 and spends colour
  # only on the one filled mode chip, so zellij does the same: the first two
  # tiers are foreground greys, and the accents stay for the tiers that
  # genuinely mark state.
  emphasis = {
    emphasis_0 = "#${colors.fg2}";
    emphasis_1 = "#${colors.fg3}";
    emphasis_2 = "#${colors.secondary}";
    emphasis_3 = "#${colors.info}";
  };
in
{
  options.dotfiles.terminals.zellij.enable = lib.mkEnableOption "zellij multiplexer" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    programs.zellij = {
      enable = true;

      settings = {
        default_shell = "nu";
        default_layout = "compact";
        pane_frames = false;
        show_startup_tips = false;

        mouse_mode = true;
        copy_on_select = true;

        keybinds = {
          shared = {
            "unbind \"Ctrl h\"" = { };
            # Drop zellij's Ctrl+q quit binding so the key falls through to
            # the running app — Helix binds it to silence/restore typos-lsp.
            "unbind \"Ctrl q\"" = { };
          };
        };

        theme = "custom";
        themes.custom = {

          # The focused pane frame follows the niri window border, so a
          # focused pane and a focused window read alike. `frame_highlight`
          # steps up to `tertiary`, the red, so the two states stay one rung
          # apart.
          frame_selected = emphasis // {
            base = "#${colors.borderActive}";
            emphasis_2 = "#${colors.grey}";
          };

          # `borderInactive` is the at-rest outline niri's inactive window
          # borders, walker and the lock ring all use. An unfocused pane
          # frame therefore reads as the resting form of a focused one, not
          # as a separate grey.
          frame_unselected = emphasis // {
            base = "#${colors.borderInactive}";
            emphasis_2 = "#${colors.tertiary}";
          };

          # Pane mode (Ctrl+p) draws the focused frame in `tertiary`, the
          # red, and the compact bar's mode name ("PANE") in a frame style's
          # `emphasis_2`. Both tiers take that same red, so the border and
          # the label read as one state. This was the theme's only green.
          frame_highlight = emphasis // {
            base = "#${colors.tertiary}";
            emphasis_2 = "#${colors.tertiary}";
          };

          # Ribbons (the tab strip and the mode indicator) copy helix's
          # statusline treatment exactly: an active chip is the background
          # colour punched out of a filled accent, and an inactive one is
          # muted text on the raised bar rather than loose text floating on
          # the background. See `ui.statusline*` in dev/helix/themes.nix.
          #
          # The fill stays `secondary`, the bright orange, rather than
          # following `frame_selected` down to `borderActive`. A ribbon
          # carries text, and bg0 on borderActive (905e29) measures 2.7:1,
          # which is not readable. On secondary it measures 5.4:1. zellij
          # has no separate token for the mode indicator, so the active tab
          # takes the same orange.
          ribbon_selected = emphasis // {
            base = "#${colors.bg0}";
            background = "#${colors.secondary}";
          };

          ribbon_unselected = emphasis // {
            base = "#${colors.fg3}";
            background = "#${colors.bgSunken}";
          };

          # The bar itself, on helix's terms: it shares helix's statusline
          # fill (the sunken background) and drops inactive text to bg3.
          text_unselected = emphasis // {
            base = "#${colors.bg3}";
            background = "#${colors.bgSunken}";
          };

          text_selected = emphasis // {
            base = "#${colors.fg3}";
            background = "#${colors.bgSunken}";
          };

          list_unselected = emphasis // {
            base = "#${colors.neutral}";
            background = "#${colors.bg0}";
          };

          list_selected = emphasis // {
            base = "#${colors.neutral}";
            background = "#${colors.bg1}";
          };

          table_title = emphasis // {
            base = "#${colors.grey}";
            background = "#${colors.bg0}";
          };

          table_cell_selected = emphasis // {
            base = "#${colors.neutral}";
            background = "#${colors.bg1}";
          };

          table_cell_unselected = emphasis // {
            base = "#${colors.neutral}";
            background = "#${colors.bg0}";
          };
        };
      };
    };
  };
}
