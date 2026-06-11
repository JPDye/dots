{
  config,
  lib,
  ...
}:

let
  cfg = config.dotfiles.desktop.lock;
  swaylock = lib.getExe config.programs.swaylock.package;
in
{
  options.dotfiles.desktop.lock.enable =
    lib.mkEnableOption "screen locking + idle management (swaylock + swayidle)"
    // {
      default = true;
    };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        # swaylock authenticates through PAM: on NixOS that needs
        # security.pam.services.swaylock (modules/system/desktop.nix); on
        # non-NixOS hosts /etc/pam.d/swaylock must exist (e.g. install the
        # distro's own swaylock once) or unlocking will fail.
        #
        # While locked, Ctrl+Alt+F1..F12 still switches to a raw tty — the
        # kernel handles VT switching, so the locker can't (and shouldn't)
        # block it. The graphical session stays locked underneath.
        programs.swaylock.enable = true; # colors come from stylix

        services.swayidle = {
          enable = true;
          timeouts = [
            {
              timeout = 300;
              command = "${swaylock} -f";
            }
            {
              # Screens off shortly after the lock kicks in; input wakes them.
              timeout = 330;
              command = "${lib.getExe config.programs.niri.package} msg action power-off-monitors";
            }
          ];
          events = [
            {
              # Guarantee the session is locked before suspend/hibernate.
              event = "before-sleep";
              command = "${swaylock} -f";
            }
            {
              # `loginctl lock-session` lands here.
              event = "lock";
              command = "${swaylock} -f";
            }
          ];
        };
      }

      (lib.mkIf config.dotfiles.desktop.niri.enable {
        programs.niri.settings.binds."Mod+Escape".action.spawn = [
          swaylock
          "-f"
        ];
      })
    ]
  );
}
