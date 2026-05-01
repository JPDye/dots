{ config, pkgs, ... }:
{
  home.packages = [ pkgs.eww ];

  programs.eww = {
    enable = true;
    configDir = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nix/eww";
  };

  systemd.user.services.eww = {
    Unit = {
      Description = "eww daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "exec";
      ExecStart = "${pkgs.eww}/bin/eww daemon --no-daemonize";
      Restart = "always";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.eww-powermenu = {
    Unit = {
      Description = "eww powermenu/bar toggle";
      PartOf = [ "graphical-session.target" ];
      After = [ "eww.service" "graphical-session.target" ];
      Wants = [ "eww.service" ];
    };
    Service = {
      Type = "exec";
      ExecStart = "${pkgs.nushell}/bin/nu ${config.home.homeDirectory}/.config/nix/eww/powermenu.nu";
      Restart = "always";
      Environment = [ "PATH=${pkgs.eww}/bin:${pkgs.niri}/bin:/run/current-system/sw/bin" ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
