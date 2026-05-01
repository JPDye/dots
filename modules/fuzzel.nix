{ lib, colors, border-style, ... }:

{
  programs.fuzzel = {
    enable = true;

    settings = {
      main = {
        icons-enabled = false;
        terminal = "alacritty";
        lines = 5;

        dpi-aware = "yes";
        font = lib.mkForce "Berkeley Mono Variable:size=11";

        horizontal-pad = 16;
        vertical-pad = 16;
      };

      colors = {
        border = lib.mkForce "${colors.red}ff";

        input = lib.mkForce "${colors.red}ff";
        text = lib.mkForce "${colors.fg2}ff";

        prompt = lib.mkForce "${colors.orange}ff";
        match = lib.mkForce "${colors.orange}ff";

        selection = lib.mkForce "${colors.bg1}ff";
        selection-text = lib.mkForce "${colors.fg1}ff";
        selection-match = lib.mkForce "${colors.orange}ff";
      };

      border = {
        width = 1;
        radius = lib.mkForce border-style.radius-int;
      };
    };
  };

  programs.tofi = {
    enable = true;

    settings = {
      anchor = "bottom-left";
      horizontal = true;

      # Height of bar
      width = 1266;
      height = 40;

      # Margin
      margin-left = 1290;
      margin-right = 8;
      margin-bottom = 8;

      # Padding
      padding-top = 7;
      padding-bottom = 0;
      padding-left = 8;
      padding-right = 8;

      # Font size
      font-size = 12;
      font = "monospace";
      min-input-width = 120;
      result-spacing = 15;

      background-color = "#${colors.bg0}";

      # Prompt
      prompt-text = " ";
      prompt-color = "#${colors.orange}";
      prompt-padding = 8;

      # Input
      input-color = "#${colors.red}";

      # Result color
      default-result-color = "#${colors.bg2}";

      # Selection text
      selection-color = "#${colors.orange}";
      selection-match-color = "#${colors.red}";
      selection-background = "#${colors.bg1}";
      selection-background-padding = 3;


      # Border color
      border-width = 2;
      border-color = "#${colors.red}";


      outline-width = 0;
      outline-color = "#${colors.bg0}";
    };
  };
}
