{ colors, ... }:

{
  services.mako = {
    enable = true;

    settings = {
      border-color = "#${colors.red}CC";
      background-color = "#${colors.bg0}";
      text-color = "#${colors.fg2}";
      default-timeout = 4000;
    };
  };
}
