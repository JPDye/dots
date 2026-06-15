{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles.system.desktop;
in
{
  options.dotfiles.system.desktop.enable =
    lib.mkEnableOption "desktop system services (dbus/portals/keyring/udisks2 + hyprlock PAM)"
    // {
      default = true;
    };

  config = lib.mkIf cfg.enable {
    services = {
      dbus = {
        enable = true;
        packages = with pkgs; [
          dbus
          blueman
          xdg-desktop-portal
          xdg-desktop-portal-wlr
          xdg-desktop-portal-gtk
          xdg-desktop-portal-gnome
        ];
      };

      gnome.gnome-keyring.enable = true;

      # System half of removable-media automounting; udiskie (the per-user
      # daemon in modules/desktop/udiskie.nix) drives it over DBus. On Arch
      # the equivalent is `pacman -S udisks2`.
      udisks2.enable = true;

      xserver.xkb.layout = "gb";
    };

    # hyprlock is installed per-user (modules/desktop/lock.nix) but
    # authenticates through PAM, which only the system config can provide.
    security.pam.services.hyprlock = { };

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome
      ];

      configPackages = [ pkgs.niri ];

      config.common.default = "gtk";
    };
  };
}
