{ config, lib, ... }:

{
  imports = [
    ./spawn.nix
    ./layout.nix
    ./window-rules.nix
    ./binds.nix
    ./animations.nix
  ];

  options.dotfiles.desktop.niri.enable = lib.mkEnableOption "niri compositor user config" // {
    default = true;
  };

  # Bits that don't fit any of the per-domain children.
  config = lib.mkIf config.dotfiles.desktop.niri.enable {
    programs.niri.settings = {
      hotkey-overlay.skip-at-startup = true;
      environment.DISPLAY = ":0";
      prefer-no-csd = true;
      screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";
      gestures.hot-corners.enable = false;
    };
  };
}
