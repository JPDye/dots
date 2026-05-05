{ config, lib, ... }:

let
  cfg = config.dotfiles.terminals.alacritty;
in
{
  options.dotfiles.terminals.alacritty.enable = lib.mkEnableOption "alacritty terminal" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    programs.alacritty = {
      enable = true;

      settings = {
        terminal.shell = "nu";

        selection = {
          save_to_clipboard = true;
        };

        cursor = {
          style = {
            shape = "beam";
            blinking = "never";
          };
        };

        window = {
          padding = {
            x = 5;
            y = 5;
          };
        };
      };
    };
  };
}
