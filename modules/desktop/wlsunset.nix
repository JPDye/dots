{ config, lib, ... }:

let
  cfg = config.dotfiles.desktop.wlsunset;
in
{
  options.dotfiles.desktop.wlsunset.enable = lib.mkEnableOption "wlsunset night light" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    services.wlsunset = {
      enable = true;
      # Rough London coordinates — only used to derive sunrise/sunset times.
      latitude = "51.5";
      longitude = "-0.1";
    };
  };
}
