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
    # GPU / OpenGL for any GUI host (both form factors want this identically —
    # so it lives here, not in a profiles/ file that would duplicate it).
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

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

    # GSettings schemas for the GTK3 file chooser. Stylix (HM scope) forces
    # Qt's platform theme to gtk, so every Qt app opens GTK3's file dialog
    # in-process, and GTK3 fatally aborts ("No GSettings schemas are
    # installed on the system") if org.gtk.Settings.FileChooser isn't on
    # XDG_DATA_DIRS. The HM-side fix (xdg.systemDirs.data in
    # theming/stylix.nix) lands in environment.d, but niri-session's
    # import-environment then overwrites XDG_DATA_DIRS in the user manager
    # with the value from /etc/set-environment — which is generated from
    # *this* option. The dirs must be here to survive into niri.service and
    # everything it spawns. Keep in sync with modules/theming/stylix.nix.
    environment.sessionVariables.XDG_DATA_DIRS = [
      "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
      "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
    ];

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
