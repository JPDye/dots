{ pkgs, ... }:
{
  home.packages = [ pkgs.awww ];

  systemd.user.services.awww = {
    Unit = {
      Description = "awww daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "exec";
      ExecStart = "${pkgs.awww}/bin/awww-daemon";
      Restart = "always";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
