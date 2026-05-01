_:

{
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
}
