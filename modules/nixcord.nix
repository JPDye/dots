_:
{
  programs.nixcord = {
    enable = true;

    config = {
      themeLinks = [
        "https://github.com/refact0r/system24/blob/main/theme/flavors/gruvbox-material.theme.css"
      ];
    };
  };
}
