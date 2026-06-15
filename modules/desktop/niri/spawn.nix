{ config, lib, ... }:

{
  config = lib.mkIf config.dotfiles.desktop.niri.enable {
    programs.niri.settings.spawn-at-startup = [
      { command = [ "xwayland-satellite" ]; }
      { command = [ "mako" ]; }
      {
        command = [
          "awww"
          "img"
          "${config.dotfiles.theme.wallpaper}"
        ];
      }
      # swaybg (the blurred backdrop) is a systemd user service now — see
      # backdrop.nix — so `switch` can restart it on a wallpaper change.
    ];
  };
}
