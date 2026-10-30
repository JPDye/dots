{ config, lib, ... }:

let
  cfg = config.dotfiles.desktop.wlsunset;
in
{
  # Off by default: the night light tints and dims the screen, and no host
  # wants it. Set the toggle true in a host overlay to opt in.
  options.dotfiles.desktop.wlsunset.enable = lib.mkEnableOption "wlsunset night light" // {
    default = false;
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
