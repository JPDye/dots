{ config, lib, ... }:

let
  cfg = config.dotfiles.apps.nixcord;
in
{
  options.dotfiles.apps.nixcord.enable = lib.mkEnableOption "discord (via nixcord)" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    programs.nixcord = {
      enable = true;

      config = {
        themeLinks = [
          "https://github.com/refact0r/system24/blob/main/theme/flavors/gruvbox-material.theme.css"
        ];
      };
    };
  };
}
