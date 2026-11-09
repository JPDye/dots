{ config, lib, ... }:

let
  cfg = config.dotfiles.desktop.awww;
in
{
  options.dotfiles.desktop.awww.enable = lib.mkEnableOption "awww wallpaper daemon" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    services.awww.enable = true;

    # niri/backdrop.nix runs `awww img` at session start, so a daemon that
    # crashed must come back fast. Upstream waits 10 s.
    systemd.user.services.awww.Service.RestartSec = lib.mkForce 1;
  };
}
