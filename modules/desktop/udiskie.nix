{ config, lib, ... }:

let
  cfg = config.dotfiles.desktop.udiskie;
in
{
  options.dotfiles.desktop.udiskie.enable =
    lib.mkEnableOption "udiskie removable-media automounter"
    // {
      default = true;
    };

  # udiskie only talks DBus to the system udisks2 daemon — that half comes
  # from modules/system/desktop.nix on NixOS, or `pacman -S udisks2` on Arch.
  config = lib.mkIf cfg.enable {
    services.udiskie = {
      enable = true;
      automount = true;
      notify = true; # plain notifications, rendered by mako
      # There is no system tray in this setup for an icon to land in.
      tray = "never";
    };
  };
}
