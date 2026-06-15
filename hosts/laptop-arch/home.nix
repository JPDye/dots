{
  config,
  lib,
  pkgs,
  mkNixGLWrap,
  ...
}:

let
  # MSI Prestige 14 AI Evo: Core Ultra 7 255H with an Arc iGPU, driven by Mesa,
  # so nixGLIntel (the Mesa variant, which also covers AMD) is the right
  # wrapper. mkNixGLWrap lives in modules/wrap-gl.nix.
  wrapGL = mkNixGLWrap "${pkgs.nixgl.nixGLIntel}/bin/nixGLIntel";
in
{
  dotfiles = {
    inherit wrapGL;

    # No slicer on this laptop: the printer lives with the desktop, which is the
    # only host that needs orca (modules/apps/orca-slicer.nix).
    apps.orca-slicer.enable = false;

    # Rootless docker as a user service (modules/dev/docker.nix). The NixOS
    # hosts get theirs from modules/system/containers.nix, so only this host
    # sets the toggle.
    dev.docker.enable = true;
  };

  home.packages = [
    # nixGL itself, exposed in PATH for ad-hoc wrapping (`nixGL <cmd>`).
    pkgs.nixgl.nixGLIntel

    # Root-level PAM setup for hyprlock (pam-setup.nix). It is also a flake
    # output, so `nix run .#arch-pam-setup` works before the first rebuild.
    # This entry puts the same command in PATH after a rebuild.
    (pkgs.callPackage ./pam-setup.nix { })
  ];

  # dbus-broker-launch reads XDG_DATA_DIRS once, when it starts, to build the
  # list of <dir>/dbus-1/services it scans. The user bus starts from the systemd
  # user manager, and that manager gets its environment from
  # environment.d/10-home-manager.conf. The only XDG_DATA_DIRS line in that file
  # is the gsettings-schema pair from xdg.systemDirs.data
  # (modules/theming/stylix.nix), and the `${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}`
  # tail contributes nothing, because no login shell has run that early. So the
  # bus scans two schema dirs and no service dir at all. Every name under
  # /usr/share or ~/.nix-profile/share then answers "not activatable":
  # ca.desrt.dconf (which aborts `home-manager switch` in dconfSettings), the
  # xdg-desktop-portal names, and the gcr prompter below. niri-session runs
  # `systemctl --user import-environment` later and repairs the manager, but the
  # bus has already read its service dirs by then.
  #
  # These entries land in the same environment.d file, which systemd reads
  # before it starts any unit, so the bus starts with a complete list. The nix
  # profile comes first, because the GUI stack on this host is the nix one. This
  # takes effect at the next login.
  xdg.systemDirs.data = [
    "${config.home.profileDirectory}/share"
    "/nix/var/nix/profiles/default/share"
    "/usr/local/share"
    "/usr/share"
  ];

  # gnome-keyring draws no dialog itself. To unlock a locked keyring it calls a
  # second D-Bus service, org.gnome.keyring.SystemPrompter, and gcr provides it.
  # With no prompter, gnome-keyring logs "couldn't create system prompt:
  # ServiceUnknown" and the app that asked for the secret waits forever. Termius
  # is the app that hurts: it reads its database key through libsecret before it
  # draws a window, so it sits on the blue splash (modules/apps/termius.nix).
  #
  # Two separate gaps make the name unactivatable on this host. Arch ships
  # /usr/lib/gcr-prompter, but it needs gtk3 and libgcr-ui-3, and neither is
  # installed here, because the GUI stack comes from nix. The session bus also
  # never sees /usr/share/dbus-1/services: dbus-broker-launch reads
  # XDG_DATA_DIRS once, when it starts, and the value it gets is the one from
  # environment.d/10-home-manager.conf. That value is only the two
  # gsettings-schema dirs from xdg.systemDirs.data (modules/theming/stylix.nix),
  # because the `${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}` tail collapses to nothing
  # when no login shell has run yet.
  #
  # ~/.local/share/dbus-1/services is the one service dir the bus always reads,
  # because it comes from XDG_DATA_HOME and not from XDG_DATA_DIRS. So put the
  # unit there and point it at nix's gcr. The `Exec=` in that file is already an
  # absolute store path, which is why this reuses the file instead of writing a
  # new one. XDG_DATA_HOME wins over XDG_DATA_DIRS, so this entry also beats
  # Arch's broken copy if /usr/share ever becomes visible to the bus.
  #
  # The NixOS hosts need none of this: services.gnome.gnome-keyring pulls in a
  # working gcr, and modules/system/desktop.nix seeds XDG_DATA_DIRS system-wide.
  xdg.dataFile."dbus-1/services/org.gnome.keyring.SystemPrompter.service".source =
    "${pkgs.gcr}/share/dbus-1/services/org.gnome.keyring.SystemPrompter.service";

  # Install niri into the user profile — on Arch there's no system-level
  # `programs.niri.enable` to do it. nixGL-wrapped so its GL/Vulkan calls find
  # the system driver libs. Run `niri-session` from a TTY (no DM session or
  # systemd unit is auto-enabled).
  programs.niri = {
    enable = true;
    # nixpkgs' niri (26.04), not niri-flake's niri-stable build (25.08). The
    # shared config uses post-25.08 features (recent-windows switcher), and
    # laptop-nix runs the nixpkgs build too, so versions stay in step.
    package = wrapGL pkgs.niri;

    settings = {
      outputs = {
        # Single 14" 1920x1200@144 panel, unscaled — the full 1920x1200 is the
        # logical space. The shared 0.333/0.5/0.666 column presets are wide enough
        # at that size, so this host leaves them alone (the desktop widens them
        # for a big monitor).
        "eDP-1" = {
          scale = 1;
          focus-at-startup = true;
        };

        "DP-3" = {
          scale = 1;
          focus-at-startup = true;
        };

        "DP-4" = {
          scale = 1;
        };

        "HDMI-A-1" = {
          scale = 1;
        };
      };

      # Tighter than the shared 16 in modules/desktop/niri/layout.nix, which the
      # small panel needs. mkForce because both sit at normal priority.
      layout.gaps = lib.mkForce 8;
    };
  };
}
