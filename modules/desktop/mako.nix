{
  config,
  lib,
  colors,
  ...
}:

let
  cfg = config.dotfiles.desktop.mako;
in
{
  options.dotfiles.desktop.mako.enable = lib.mkEnableOption "mako notification daemon" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    services.mako = {
      enable = true;

      settings = {
        border-color = "#${colors.red}CC";
        background-color = "#${colors.bg0}";
        text-color = "#${colors.fg2}";
        default-timeout = 4000;
      };
    };
  };
}
