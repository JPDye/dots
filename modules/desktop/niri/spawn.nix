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
      {
        command = [
          "swaybg"
          "-m"
          "fill"
          "-i"
          "${config.dotfiles.theme.wallpaperBlurred}"
        ];
      }
    ];
  };
}
