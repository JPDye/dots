{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.desktop.swww;
in
{
  options.dotfiles.desktop.swww.enable = lib.mkEnableOption "awww wallpaper daemon" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
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
  };
}
