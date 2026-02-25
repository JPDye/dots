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
