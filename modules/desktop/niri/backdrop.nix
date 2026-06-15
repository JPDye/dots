{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.desktop.niri;
  inherit (config.dotfiles) theme;
in
{
  config = lib.mkIf cfg.enable {
    # swaybg paints the blurred backdrop in niri's layer behind the columns.
    # Modelled as a user service (rather than a niri spawn-at-startup) so that
    # `switch` can restart it with the new image — see applyWallpaper below.
    # It still starts on login via graphical-session.target, exactly like the
    # awww-daemon service in swww.nix.
    systemd.user.services.swaybg = {
      Unit = {
        Description = "swaybg backdrop (blurred wallpaper)";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.swaybg}/bin/swaybg -m fill -i ${theme.wallpaperBlurred}";
        Restart = "always";
        RestartSec = 1;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    # Re-apply the wallpaper on every `switch` so changing
    # dotfiles.theme.wallpaper (or the blur sigma) no longer needs a relogin:
    #   - awww is a daemon; `awww img` just sends the new image over its socket
    #     (works even without WAYLAND_DISPLAY, e.g. from a nixos-rebuild).
    #   - swaybg bakes the path into its ExecStart, so it needs a restart to
    #     pick up the new blur; systemd runs it inside the session with the
    #     right WAYLAND_DISPLAY.
    # Guarded to be a clean no-op when no graphical session is live (TTY
    # switch, headless rebuild, first boot before login).
    home.activation.applyWallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if ${pkgs.awww}/bin/awww query >/dev/null 2>&1; then
        run ${pkgs.awww}/bin/awww img ${theme.wallpaper} || true
      fi
      if ${pkgs.systemd}/bin/systemctl --user is-active graphical-session.target >/dev/null 2>&1; then
        run ${pkgs.systemd}/bin/systemctl --user daemon-reload || true
        run ${pkgs.systemd}/bin/systemctl --user restart swaybg.service || true
      fi
    '';
  };
}
