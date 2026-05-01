{ pkgs, ... }:
{
  home.packages = [ pkgs.swww ];

  systemd.user.services.swww = {
    Unit = {
      Description = "swww daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "exec";
      ExecStart = "${pkgs.swww}/bin/swww-daemon";
      Restart = "always";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
