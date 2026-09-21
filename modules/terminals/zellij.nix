{
  config,
  lib,
  colors,
  ...
}:

let
  cfg = config.dotfiles.terminals.zellij;
  emphasis = {
    emphasis_0 = "#${colors.primary}";
    emphasis_1 = "#${colors.secondary}";
    emphasis_2 = "#${colors.tertiary}";
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

          # The focused pane frame takes the same `border` the niri window
          # border uses, so a focused pane and a focused window read alike.
          frame_selected = emphasis // {
            base = "#${colors.border}";
            emphasis_2 = "#${colors.grey}";
          };

          # `mid` is the palette's at-rest red tint, the same token niri's
          # inactive borders and the lock ring use. An unfocused frame
          # therefore reads as a dimmed version of the focused red, not as a
          # separate grey.
          frame_unselected = emphasis // {
            base = "#${colors.neutral}";
            emphasis_2 = "#${colors.success}";
          };

          frame_highlight = emphasis // {
            base = "#${colors.secondary}";
            emphasis_2 = "#${colors.success}";
          };

          ribbon_selected = emphasis // {
            base = "#${colors.bg0}";
            background = "#${colors.primary}";
          };

          ribbon_unselected = emphasis // {
            base = "#${colors.primary}";
            background = "#${colors.bg0}";
          };

          text_unselected = emphasis // {
            base = "#${colors.neutral}";
            background = "#${colors.bg0}";
          };

          text_selected = emphasis // {
            base = "#${colors.bg2}";
            background = "#${colors.bg0}";
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
