{ config, lib, ... }:

let
  cfg = config.dotfiles.desktop.swayosd;
in
{
  options.dotfiles.desktop.swayosd.enable = lib.mkEnableOption "swayosd on-screen display" // {
    default = true;
  };

  config = lib.mkIf cfg.enable { services.swayosd.enable = true; };
}
