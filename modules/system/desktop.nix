{ pkgs, ... }:

{
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

    xserver.xkb.layout = "gb";
  };

  # swaylock is installed per-user (modules/desktop/lock.nix) but
  # authenticates through PAM, which only the system config can provide.
  security.pam.services.swaylock = { };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];

    configPackages = [ pkgs.niri ];

    config.common.default = "gtk";
  };
}
