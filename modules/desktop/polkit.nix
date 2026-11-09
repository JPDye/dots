{ config, lib, ... }:

let
  cfg = config.dotfiles.desktop.polkit;
in
{
  options.dotfiles.desktop.polkit.enable = lib.mkEnableOption "polkit-gnome auth agent" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    services.polkit-gnome.enable = true;

    # Upstream sets no Restart. Keep the agent coming back after a crash,
    # or every later polkit prompt fails until the next login.
    systemd.user.services.polkit-gnome.Service = {
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };
}
