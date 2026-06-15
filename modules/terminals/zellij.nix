{
  config,
  lib,
  colors,
  ...
}:

let
  cfg = config.dotfiles.terminals.zellij;
  emphasis = {
    emphasis_0 = "#${colors.orange}";
    emphasis_1 = "#${colors.pink}";
    emphasis_2 = "#${colors.red}";
    emphasis_3 = "#${colors.yellow}";
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

          frame_selected = emphasis // {
            base = "#${colors.red}";
            emphasis_2 = "#${colors.grey}";
          };

          frame_unselected = emphasis // {
            base = "#${colors.bg2}";
            emphasis_2 = "#${colors.green}";
          };

          frame_highlight = emphasis // {
            base = "#${colors.orange}";
            emphasis_2 = "#${colors.green}";
          };

          ribbon_selected = emphasis // {
            base = "#${colors.bg0}";
            background = "#${colors.orange}";
          };

          ribbon_unselected = emphasis // {
            base = "#${colors.orange}";
            background = "#${colors.bg0}";
          };

          text_unselected = emphasis // {
            base = "#${colors.mid}";
            background = "#${colors.bg0}";
          };

          text_selected = emphasis // {
            base = "#${colors.bg2}";
            background = "#${colors.bg0}";
          };

          list_unselected = emphasis // {
            base = "#${colors.mid}";
            background = "#${colors.bg0}";
          };

          list_selected = emphasis // {
            base = "#${colors.mid}";
            background = "#${colors.bg1}";
          };

          table_title = emphasis // {
            base = "#${colors.grey}";
            background = "#${colors.bg0}";
          };

          table_cell_selected = emphasis // {
            base = "#${colors.mid}";
            background = "#${colors.bg1}";
          };

          table_cell_unselected = emphasis // {
            base = "#${colors.mid}";
            background = "#${colors.bg0}";
          };
        };
      };
    };
  };
}
