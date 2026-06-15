{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.desktop.polkit;
in
{
  options.dotfiles.desktop.polkit.enable = lib.mkEnableOption "polkit-gnome auth agent" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.polkit-gnome-authentication-agent-1 = {
      Unit = {
        Description = "polkit-gnome-authentication-agent-1";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
