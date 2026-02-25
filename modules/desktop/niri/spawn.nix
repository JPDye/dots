{
  config,
  inputs,
  lib,
  ...
}:

{
  config = lib.mkIf config.dotfiles.desktop.niri.enable {
    programs.niri.settings.spawn-at-startup = [
      { command = [ "xwayland-satellite" ]; }
      { command = [ "mako" ]; }
      {
        command = [
          "awww"
          "img"
          "${inputs.self}/wallpapers/socrates.jpg"
        ];
      }
      {
        command = [
          "swaybg"
          "-m"
          "fill"
          "-i"
          "${inputs.self}/wallpapers/socrates-blur.png"
        ];
      }
    ];
  };
}
